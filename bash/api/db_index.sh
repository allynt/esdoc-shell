#!/bin/bash

# Import utils.
source $ESDOC_HOME/bash/init.sh

# Main entry point.
main()
{
    log "API-DB: indexing document facets ..."
	activate_venv api
	python $ESDOC_DIR_API/jobs/run_db_index.py
    log "API-DB: indexed document facets"
}

# Invoke entry point.
main
