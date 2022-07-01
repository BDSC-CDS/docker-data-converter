The documentation for the configuration files is available at https://github.com/CHUV-DS/RDF-i2b2-converter#readme .

To run the data converter, you should
- Have docker installed
- Have cloned this repository
- Create a data directory, an output directory, a debug directory for logs and verbose tables, and if necessary a context directory, where complementary graphs such as units definition shall lie (can be empty but should exist)
- Place yourself in the current repository
- Change the variables in the Makefile to reflect your directories absolute paths
- run
   $ make build
- Perform a debug run first: place your debug ontology tables in your debug directory, 
	- change the "DEBUG" variable in config/i2b2_rdf_config.json to "True" (with quotes)
	- run   $ make debug

- When done, take a look at the logfiles and if you are satisfied
	- change the "DEBUG" variable in config/i2b2_rdf_config.json back to "False" (with quotes)
   	- run   $ make up-d

- Collect all the .csv files in the output directory (you can ignore lowercase-files which are message-passing logs from the ontology converter to the data converter)



