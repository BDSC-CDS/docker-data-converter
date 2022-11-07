#COPY YOUR DEBUG (ONTOLOGY WITH CLEARTEXT BASECODES) TABLES LOCATION HERE
DEBUG_TABLES_LOCATION = /home/${USER}/debug_tables

#COPY YOUR ABSOLUTE PATH TO THE FOLDER CONTAINING THE UNITS GRAPH HERE
UNITS_GRAPH_LOCATION = /home/${USER}/units

#COPY YOUR ABSOLUTE PATH TO THE OUTPUT TABLES FOLDER HERE.
OUTPUT_TABLES_LOCATION = /home/${USER}/bioref_tables_synthetic

# COPY YOUR ABSOLUTE PATH TO THE DATA GRAPHS HERE
DATALOCATION = /home/${USER}/synthetic-data/

CONFIG_FOLDER = /home/${USER}/docker-data-converter/config


build:
	docker build . -t data-converter:latest   
up:
	sed -i 's/"DEBUG":"True"/"DEBUG":"False"/g' $(CONFIG_FOLDER)/i2b2_rdf_config.json
	docker run -it --name data_converter -v $(DATALOCATION):/data -v $(UNITS_GRAPH_LOCATION):/units -v  $(OUTPUT_TABLES_LOCATION):/output_tables -v $(CONFIG_FOLDER):/config data-converter:latest

up-d:
	sed -i 's/"DEBUG":"True"/"DEBUG":"False"/g' $(CONFIG_FOLDER)/i2b2_rdf_config.json
	docker run -it -d --name data_converter -v $(DATALOCATION):/data -v $(OUTPUT_TABLES_LOCATION):/output_tables -v $(UNITS_GRAPH_LOCATION):/units -v $(CONFIG_FOLDER):/config data-converter:latest

follow:
	docker logs --follow data_converter
stop:
	docker stop data_converter
down:
	docker stop data_converter
	docker rm data_converter

wipe:
	make down
	docker image rm data-converter:latest
bash:
	docker exec -it data_converter bash
	
debug: 
	sed -i 's/"DEBUG":"False"/"DEBUG":"True"/g' $(CONFIG_FOLDER)/i2b2_rdf_config.json
	docker run -it -d --name data_converter -v $(DATALOCATION):/data -v $(DEBUG_TABLES_LOCATION):/output_tables -v $(UNITS_GRAPH_LOCATION):/units -v $(CONFIG_FOLDER):/config data-converter:latest

