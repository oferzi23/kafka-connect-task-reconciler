# kafka-connect-task-reconciler

this script is intended to run as a service and is responsible for automating kafka connect failed tasks restart.
this script should be run without any special arguments as the endpoint to scan and reconcile for should be provided using environment variables.

this script will run on an interval, query the connect cluster for failed tasks and restart them.

# Requirements:

this script expect jq and curl to be installed

# Usage
Several environment variables are supported to configure the behaviour of this script:

EVENTLOOP_INTERVAL - determines how long will we wait between each cycle of reconciliation
CONNECT_ENDPOINT_HOSTNAME - Hostname where kafka connect REST API is available
CONNECT_PORT - Port where kafka connect REST API is available

# Disclaimer
i am not following up on kafka connect REST API changelog so breaking changes might occur in the future.
feel free to PR updates and new stuff if you feel like it.