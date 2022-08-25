#COPY YOUR DEBUG (ONTOLOGY WITH CLEARTEXT BASECODES) TABLES LOCATION HERE
DEBUG_TABLES_LOCATION = /home/ju5750/debug_tables

#COPY YOUR ABSOLUTE PATH TO THE FOLDER CONTAINING THE UNITS GRAPH HERE
UNITS_GRAPH_LOCATION = /home/ju5750/units

#COPY YOUR ABSOLUTE PATH TO THE OUTPUT TABLES FOLDER HERE.
OUTPUT_TABLES_LOCATION = /home/ju5750/output_tables

# COPY YOUR ABSOLUTE PATH TO THE DATA GRAPHS HERE
DATALOCATION = /home/ju5750/data

CONFIG_FOLDER = /home/ju5750/docker-data-converter/config


build:
	docker build . -t data-converter:latest   
up:
	docker run -it --name data_converter -v $(DATALOCATION):/data -v $(UNITS_GRAPH_LOCATION):/units -v  $(OUTPUT_TABLES_LOCATION):/output_tables -v $(CONFIG_FOLDER):/config data-converter:latest

up-d:
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
	docker run -it -d --name data_converter -v $(DATALOCATION):/data -v $(DEBUG_TABLES_LOCATION):/output_tables -v $(UNITS_GRAPH_LOCATION):/units -v $(CONFIG_FOLDER):/config data-converter:latest

