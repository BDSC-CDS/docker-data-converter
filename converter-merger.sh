#!/usr/bin/bash
set -Eeuo pipefail


# Use this script by calling it with the N paths to folders containing the N shares of data (either raw CSV/converted CSV, see below)
# You will be prompted for a destination folder
#
# Ex: $ bash merge.sh ../data/run1/ ../converter_output/run2 ../converter_output/run3
# OR with only one argument being a root directory containing the n directories mentioned above
# Ex: $ bash merge.sh ../data_batches/
#
# With run1, run2 and run3 directories each containing a set of RDF data graphs.
#
# If you already converted your data, use the script in the same fashion with the flag --merge-only, and where the subfolders  contain your converted CSV data files. 
# If you only want to convert your data but not merge the resulting runs, use the flag --convert-only.

main () {
	tgt="all"
	# Arg parsing: if using a flag to target only one of the two features
	case $1 in
		"--convert-only")
			shift
			tgt="convert"
			;;
		"--merge-only")
			shift
			tgt="merge"
			;;
		--*)
			echo "Unrecognized flag, aborting."
			exit 1
			;;
		*)
			;;
	esac
	echo "Please enter a path to a global destination directory. It will be created automatically if not already there."
	read -r DESTDIR
	# Adding trailing slash
	[[ "${DESTDIR}" != */ ]] && DESTDIR="${DESTDIR}/"
	mkdir -p $DESTDIR
	if [ $# == 1 ] ; then
		lsmerges=($(ls $1))
		TOMERGEDIRS=("${lsmerges[@]/#/$1\/}")
		echo "dirs to merge: ${TOMERGEDIRS[@]}"
		lssource=($(ls $1))
		SOURCEDIRS=("${lssource[@]/#/$1\/}")
	else
		TOMERGEDIRS=$@
		SOURCEDIRS=$@
	fi	
	case $tgt in 
		"convert")
			echo "Ready to convert the files."
			TOMERGEDIRS=()
			loop_convert ${SOURCEDIRS[@]} 
			echo "The graphs were converted and the outputs are available in the following directories: ${TOMERGEDIRS[@]}."
			;;
		"merge")
			echo "Ready to merge the records located in ${TOMERGEDIRS[@]}."
			merge ${TOMERGEDIRS[@]}
			;;
		*)	
			echo "Ready to both convert and merge."
			# Reinit folders to be merged since the converting loop will overwrite the list with its outputs
			TOMERGEDIRS=()	
			loop_convert ${SOURCEDIRS[@]}
			merge ${TOMERGEDIRS[@]}
			;;
	esac
}



loop_convert () {
	### This function takes as input a list of data directories.
	### Convert each of the graphs to a dedicated folder.
	### Update the TMPDIRS array with the path to each folder (in-order w.r. to the input list).
	recipe="up-d"
	echo "All batches will be converted in non-debug mode. If OK press Enter, if you want debug mode type 'debug' and press Enter."
	read mode
	case $mode in 
		"")
			echo "About to start converting. Make sure the 'migrations_logs' file (if applicable) is in $DESTDIR , and the ontology tables if you want the (optional) consistency check to pass."
			;;
		"debug")
			echo "Debug mode activated for all batches. Make sure the ontology tables and the 'migration_logs' file are in $DESTDIR are also debug mode."
			recipe="debug"
			;;
		*)
			echo "Exiting."
			exit 1
			;;
	esac
	for ((i=1; i<= $# ; i++)) ; do 
                dataloc=${!i}
		# Adding trailing slash
		[[ "${dataloc}" != */ ]] && dataloc="${dataloc}/"
		# Turning the arguments into absolute paths for docker volume binding (mandatory)
		[[ "${dataloc}" != /* ]] && dataloc="$(cd "$(dirname "$dataloc")"; pwd)/$(basename "$dataloc")/"
		[[ "${DESTDIR}" != /* ]] && DESTDIR="$(cd "$(dirname "$DESTDIR")"; pwd)/$(basename "$DESTDIR")/"
                destloc="${DESTDIR}tables_batch${i}/"
		TOMERGEDIRS+=($destloc)
                mkdir -p $destloc
		(cp "${DESTDIR}migrations_logs.json" $destloc && cp "${DESTDIR}MODIFIER_DIMENSION.csv" && "${DESTDIR}CONCEPT_DIMENSION.csv" $destloc) || true
		override="DATALOCATION=${dataloc} OUTPUT_TABLES_LOCATION=${destloc}"
		run="make $recipe $override"
		$run || (make build $override && $run)
		echo "Converting batch $i of ${#}, you can keep track of it by running 'make follow'"
                make follow > ${DESTDIR}logs.txt
		docker wait data_converter 
                make down 
		(rm "${destloc}CONCEPT_DIMENSION.csv ${destloc}MODIFIER_DIMENSION.csv") || true
		[[ -f ${destloc}PATIENT_DIMENSION.csv ]] || (echo "The tables were not created." && exit 1)
	done
	echo "Finished converting all the batches."
	return 
}

#################################################
### MERGING BATCHES INTO ONE i2b2 STAR SCHEMA ###
#################################################


merge () {
	### This function takes as input a list of directories, each containing CSV data files for i2b2.
	### It merges all data files into one of each kind, removing duplicates and reindexing if necessary.
	### The output files are written in the DESTDIR folder.

	OF_BASE="OBSERVATION_FACT.csv"
	PD_BASE="PATIENT_DIMENSION.csv"
	PM_BASE="PATIENT_MAPPING.csv"
	VD_BASE="VISIT_DIMENSION.csv"
	EM_BASE="ENCOUNTER_MAPPING.csv"
	PR_BASE="PROVIDER_DIMENSION.csv"
	
	OFFSET_PATIENT=0
	OFFSET_ENCOUNTER=0
	OFFSET_TSI=0


	for  (( i=1; i <= "$#"; i++ )); do 
		# Add a trailing slash if necessary
		dir=${!i}
		[[ "${dir}" != */ ]] && dir="${dir}/"
		OF="${dir}$OF_BASE"
		PM="${dir}$PM_BASE"
		PD="${dir}$PD_BASE"
		EM="${dir}$EM_BASE"
		VD="${dir}$VD_BASE"
		PR="${dir}$PR_BASE"
	 
		if ! [ -f "$OF" -a -f "$PM" -a -f "$PD" -a -f "$EM" -a -f "$VD" -a -f "$PR" ] ; then
			echo "Please check directory ${!i} is full (OBSERVATION_FACT, PATIENT_MAPPING, PATIENT_DIMENSION, VISIT_DIMENSION, ENCOUNTER_MAPPING)"
			exit 1
		fi
		# Initialize files with the header if they don't already exist
		[ -f ${DESTDIR}${PM_BASE} ] || awk 'NR==1' "$PM" > ${DESTDIR}${PM_BASE}
		[ -f ${DESTDIR}${PD_BASE} ] || awk 'NR==1' "$PD" > ${DESTDIR}${PD_BASE}
		[ -f ${DESTDIR}${OF_BASE} ] || awk 'NR==1' "$OF" > ${DESTDIR}${OF_BASE}
		[ -f ${DESTDIR}${EM_BASE} ] || awk 'NR==1' "$EM" > ${DESTDIR}${EM_BASE}
		[ -f ${DESTDIR}${VD_BASE} ] || awk 'NR==1' "$VD" > ${DESTDIR}${VD_BASE}
		[ -f ${DESTDIR}${PR_BASE} ] || awk 'NR==1' "$PR" > ${DESTDIR}${PR_BASE}
		echo "Beginning of iteration $i : shifting will be of $OFFSET_PATIENT patients and $OFFSET_ENCOUNTER encounters"	

		# Patient number is first field in PATIENT_DIMENSION, second field in VISIT_DIMENSION, third field in PATIENT_MAPPING
		awk -v offset=$OFFSET_PATIENT '(NR>1), $3+=offset' FS=, OFS=, "$PM" >> ${DESTDIR}${PM_BASE}
		awk -v offset=$OFFSET_PATIENT '(NR>1), $1+=offset' FS=, OFS=, "$PD" >> ${DESTDIR}${PD_BASE}

		# Add offset to the encounter numbers as well. Discard -1 encounters.
	        # No need to update patient num in EM because it's empty (-1)
		awk -v offset=$OFFSET_ENCOUNTER '(NR>1) && ($4>0), $4+=offset' FS=, OFS=, "$EM" >> ${DESTDIR}${EM_BASE}
		awk -v offset=$OFFSET_ENCOUNTER '(NR>1) && ($1>0), $1+=offset' FS=, OFS=, "$VD" > "${DESTDIR}tmp_vd"
		awk -v offset=$OFFSET_PATIENT '$2+=offset' FS=, OFS=, "${DESTDIR}tmp_vd" >> ${DESTDIR}${VD_BASE} && rm "${DESTDIR}tmp_vd"

		# Propagate all the changes in OBSERVATION_FACT (except for -1 encounters which we do not touch)
		awk -v offset=$OFFSET_PATIENT '(NR>1), $2+=offset' FS=, OFS=, "$OF" > "${DESTDIR}tmp_of"
		awk -v offset=$OFFSET_ENCOUNTER '($1>0) ? $1+=offset : $1=$1' FS=, OFS=, "${DESTDIR}tmp_of" > "${DESTDIR}tmp2_of" && rm "${DESTDIR}tmp_of"
		awk -v offset=$OFFSET_TSI '$NF+=offset' FS=, OFS=, "${DESTDIR}tmp2_of" >> ${DESTDIR}${OF_BASE} && rm "${DESTDIR}tmp2_of"
	
		# Update PROVIDER_DIMENSION by appending the new providers if not already in the target file 
		comm -13 <(sort ${DESTDIR}${PR_BASE}) <(sort ${PR}) >> ${DESTDIR}${PR_BASE}

		# Update all offsets
		OFFSET_PATIENT=$(($OFFSET_PATIENT+$(wc -l < $PD) -1))
		OFFSET_ENCOUNTER=$(($OFFSET_ENCOUNTER+$(wc -l < $VD) -1))
		OFFSET_TSI=$(($OFFSET_TSI+$(wc -l < $OF) -1))
	done
}

main "$@"
