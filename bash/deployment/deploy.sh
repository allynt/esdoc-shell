#!/bin/bash

# ###############################################################
# SECTION: INIT
# ###############################################################

# Set action.
declare ACTION=`echo $1 | tr '[:upper:]' '[:lower:]' | tr '-' '_'`

# Set root path.
declare DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
cd ../..
declare DIR="$( pwd )"

# Set paths.
declare ESDOC_DIR_WEBAPPS=$HOME"/webapps"
declare ESDOC_DIR_REPOS=$DIR"/repos"
declare ESDOC_DIR_RESOURCES=$DIR"/resources"
declare ESDOC_DIR_TMP=$DIR"/ops/tmp"
declare ESDOC_DIR_CONFIG=$DIR"/ops/config"
declare ESDOC_DIR_VENV=$DIR"/ops/venv"
declare ESDOC_DIR_API=$ESDOC_DIR_REPOS/esdoc-api
declare ESDOC_DIR_PYESDOC=$ESDOC_DIR_REPOS/esdoc-py-client
declare ESDOC_DIR_DAEMONS=$DIR"/ops/daemons"

# Set vars:
declare RELEASE_TYPE=$2
declare RELEASE_VERSION=$3
declare API_NAME=$RELEASE_TYPE"_"$RELEASE_VERSION"_api"
declare API_HOME=$ESDOC_DIR_WEBAPPS/$API_NAME
declare API_DB_FILE=$ESDOC_DIR_RESOURCES"/api-db"
declare API_DB_FILE_ZIPPED=$API_DB_FILE".zip"
declare API_DB_NAME=$RELEASE_TYPE"_"$RELEASE_VERSION"_api"
declare API_DB_USER=$RELEASE_TYPE"_"$RELEASE_VERSION"_api"
declare API_DB_PWD=$4
declare API_PORT=$5


# ###############################################################
# SECTION: HELPER FUNCTIONS
# ###############################################################

# Wraps standard echo by adding ES-DOC prefix.
log()
{
	tabs=''
	if [ "$1" ]; then
		if [ "$2" ]; then
			for ((i=0; i<$2; i++))
			do
				tabs+='\t'
			done
	    	echo -e 'ES-DOC :: '$tabs$1
	    else
	    	echo -e "ES-DOC :: "$1
	    fi
	else
	    echo -e "ES-DOC ::"
	fi
}

# Outputs a separator.
log_banner()
{
	echo "---------------------------------------------"
}

# Resets temporary folder.
reset_tmp()
{
	rm -rf $ESDOC_DIR_TMP/*
	mkdir -p $ESDOC_DIR_TMP
}

# ###############################################################
# SECTION: MAIN
# ###############################################################

# Updates source code.
update_source()
{
	# Update web-service code.
	rm -rf $API_HOME/app/esdoc_api
	cp -r $ESDOC_DIR_REPOS/esdoc-api/esdoc_api $API_HOME/app
	rm -rf $API_HOME/app/pyesdoc
	cp -r $ESDOC_DIR_REPOS/esdoc-py-client/pyesdoc $API_HOME/app

	# Update web-apps code.
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_compare/*
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_search/*
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_splash/*
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_static/*
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_view/*
	rm -rf $ESDOC_DIR_WEBAPPS/$1_$2_demo/*
	_install_source_static $1 $2

	# ... clear up temp files.
	reset_tmp
}


# Installs static source code.
_install_source_api()
{
	# ... create api source code folder
	mkdir -p $API_HOME/app

	# ... copy source code
	cp -r $ESDOC_DIR_REPOS/esdoc-api/esdoc_api $API_HOME/app
	cp -r $ESDOC_DIR_REPOS/esdoc-py-client/pyesdoc $API_HOME/app

	# ... copy templates to temp folder
	cp -r $ESDOC_DIR_RESOURCES/template-webfaction-*.* $ESDOC_DIR_TMP

	# ... format templates
	declare -a templates=(
	        $ESDOC_DIR_TMP"/template-webfaction-api-crontab.txt"
	        $ESDOC_DIR_TMP"/template-webfaction-api-supervisord.conf"
	        $ESDOC_DIR_TMP"/template-webfaction-api.conf"
	        $ESDOC_DIR_TMP"/template-webfaction-pyesdoc.conf"
	)
	for template in "${templates[@]}"
	do
	        perl -e "s/RELEASE_TYPE/"$RELEASE_TYPE"/g;" -pi $(find $template -type f)
	        perl -e "s/API_NAME/"$API_NAME"/g;" -pi $(find $template -type f)
	        perl -e "s/API_ENVIRONMENT/"$1"/g;" -pi $(find $template -type f)
	        perl -e "s/API_VERSION/"$2"/g;" -pi $(find $template -type f)
	        perl -e "s/API_DB_USER/"$API_DB_USER"/g;" -pi $(find $template -type f)
	        perl -e "s/API_DB_NAME/"$API_DB_NAME"/g;" -pi $(find $template -type f)
	        perl -e "s/API_DB_PWD/"$3"/g;" -pi $(find $template -type f)
	        perl -e "s/API_PORT/"$4"/g;" -pi $(find $template -type f)
	done

	# ... copy formatted templates
	mv $ESDOC_DIR_TMP"/template-webfaction-api-crontab.txt" $ESDOC_DIR_CONFIG"/api-crontab.txt"
	mv $ESDOC_DIR_TMP"/template-webfaction-api-supervisord.conf" $ESDOC_DIR_DAEMONS"/api/supervisord.conf"
	mv $ESDOC_DIR_TMP"/template-webfaction-api.conf" $ESDOC_DIR_CONFIG"/api.conf"
	mv $ESDOC_DIR_TMP"/template-webfaction-pyesdoc.conf" $ESDOC_DIR_CONFIG"/pyesdoc.conf"

	# ... clear up temp files.
	reset_tmp
}

# Installs static source code.
_install_source_static()
{
	# ... comparator micro-site
	cp -r $ESDOC_DIR_REPOS/esdoc-web/comparator/* $ESDOC_DIR_WEBAPPS/$1_$2_compare
	rm $ESDOC_DIR_WEBAPPS/$1_$2_compare/index-dev.html

	# ... search micro-site
	cp -r $ESDOC_DIR_REPOS/esdoc-web/search/* $ESDOC_DIR_WEBAPPS/$1_$2_search

	# ... splash micro-site
	cp -r $ESDOC_DIR_REPOS/esdoc-web/splash/* $ESDOC_DIR_WEBAPPS/$1_$2_splash

	# ... static files
	cp -r $ESDOC_DIR_REPOS/esdoc-web/static/* $ESDOC_DIR_WEBAPPS/$1_$2_static
	cp -r $ESDOC_DIR_REPOS/esdoc-web/plugin/bin/latest/* $ESDOC_DIR_WEBAPPS/$1_$2_static
	mkdir -p $ESDOC_DIR_WEBAPPS/$1_$2_static/ontologies/cim/1
	cp -r $ESDOC_DIR_REPOS/esdoc-cim/v1/xsd/*.xsd $ESDOC_DIR_WEBAPPS/$1_$2_static/ontologies/cim/1

	# ... viewer micro-site
	cp -r $ESDOC_DIR_REPOS/esdoc-web/viewer/* $ESDOC_DIR_WEBAPPS/$1_$2_view

	# ... viewer demo micro-site
	cp -r $ESDOC_DIR_REPOS/esdoc-web/viewer-demo/* $ESDOC_DIR_WEBAPPS/$1_$2_demo
}

# Installs source code.
install_source()
{
	_install_source_api $1 $2 $3 $4
	_install_source_static $1 $2
}

# Updates cron tabe.
update_crontab()
{
	crontab $ESDOC_DIR_CONFIG/api-crontab.txt
}

# Restores db from backup.
restore_db()
{
	unzip -q $API_DB_FILE_ZIPPED -d $ESDOC_DIR_RESOURCES
	pg_restore -U $API_DB_USER -d $API_DB_NAME $API_DB_FILE
	rm $API_DB_FILE
}

# Activate API virtual environment.
_activate_api_venv()
{
	export PYTHONPATH=$PYTHONPATH:$ESDOC_DIR_PYESDOC
	export PYTHONPATH=$PYTHONPATH:$ESDOC_DIR_API
	source $ESDOC_DIR_VENV/api/bin/activate
}

# Start api daemon.
start_api_daemon()
{
	_activate_api_venv
	supervisord -c $ESDOC_DIR_DAEMONS/api/supervisord.conf
}

# Stop api daemon.
stop_api_daemon()
{
	_activate_api_venv
	supervisorctl -c $ESDOC_DIR_DAEMONS/api/supervisord.conf stop api
	supervisorctl -c $ESDOC_DIR_DAEMONS/api/supervisord.conf shutdown
}

# Invoke action.
$ACTION $RELEASE_TYPE $RELEASE_VERSION $API_DB_PWD $API_PORT

# Reset temporary folder.
reset_tmp

# End.
log_banner

exit 0