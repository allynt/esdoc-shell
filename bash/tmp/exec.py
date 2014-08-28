#  Module imports.
import os
import sys

import pyesdoc
import pyesdoc.db.index as index
import pyesdoc.db.ingest as ingest
import pyesdoc.db.session as session
import pyesdoc.db.utils as repo_utils
import pyesdoc.db.models as models

# Conditionally import api.
try:
    import esdoc_api
except ImportError:
    pass
else:
    import esdoc_api.lib.api.comparator_setup as comparator_setup
    import esdoc_api.lib.api.visualizer_setup as visualizer_setup

# Conditionally import web-service.
try:
    import esdoc_ws
except ImportError:
    print "WS not imported"
    pass

import utils


# Script configuration.
cfg = None

# Set of comparators for which to write setup data in json format.
_COMPARATORS = {
    'CMIP5' : ['c1']
}

# Set of visualizers for which to write setup data in json format.
_VISUALIZERS = {

}


def _start_api_db_session():
    """Starts an api db session."""
    session.start(cfg.api.db)


def _end_api_db_session():
    """Ends an api db session."""
    session.end()


def _wrap_api_db_session(task, param=None):
    """Wraps a function with a call to db session start/end."""
    # Start session.
    _start_api_db_session()

    # Perform work.
    if param:
        task(param)
    else:
        task()

    # End session.
    _end_api_db_session()


def _db_setup():
    """Execute db initialization."""
    _wrap_api_db_session(session.create_repo)


def _db_index():
    """Execute db indexation."""
    _wrap_api_db_session(index.execute)


def _db_ingest():
    """Execute db ingestion."""
    def do():
        # Unpack throttle.
        try:
            throttle = int(sys.argv[2])
        except IndexError:
            throttle = 0
        except ValueError:
            msg = "Throttle must be a positive integer value"
            raise ValueError(msg)

        # Unpack type filter.
        try:
            type_filter = sys.argv[3]
        except IndexError:
            type_filter = None

        # Execute.
        ingest.execute(throttle, type_filter)

    _wrap_api_db_session(do)


def _db_index_reset():
    """Execute db indexation."""
    def do_index():
        index.execute(True)

    _wrap_api_db_session(do_index)


def _api_setup_comparator():
    """Write api comparator setup data."""
    def _do():
        for project in _COMPARATORS:
            for type in _COMPARATORS[project]:
                comparator_setup.write_comparator_json(project, type)

    _wrap_api_db_session(_do)


def _api_setup_visualizer():
    """Write api visualizer setup data."""
    def _do():
        for project in _VISUALIZERS:
            for type in _VISUALIZERS[project]:
                visualizer_setup.write_visualizer_json(project, type)

    _wrap_api_db_session(_do)


def _api_stats():
    """Write api statistical data."""
    _wrap_api_db_session(repo_utils.write_doc_stats)


def _ws_run():
    """Launches web service application."""
    esdoc_ws.run()


def _init_config():
    """Initialize configuration."""
    global cfg

    fp = os.path.dirname(os.path.abspath(__file__))
    fp = os.path.join(fp, "config.json")
    cfg = utils.json_file_to_namedtuple(fp)


# Map of supported actions.
_actions = {
    "db-setup": _db_setup,
    "db-index": _db_index,
    "db-index-reset": _db_index_reset,
    "db-ingest": _db_ingest,
    "api-setup-comparator": _api_setup_comparator,
    "api-setup-visualizer": _api_setup_visualizer,
    "api-stats": _api_stats,
    "ws-run": _ws_run
}


def main():
    """Main entry point."""
    # Validate action.
    if sys.argv[1] not in _actions:
        raise NotImplementedError(sys.argv[1])

    # Initialize configuration.
    _init_config()

    # Invoke action.
    _actions[sys.argv[1]]()



if __name__ == '__main__':
    main()
