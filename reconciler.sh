#!/bin/bash

# set -x
set -e
set -u

# Constants
EVENTLOOP_INTERVAL="${EVENTLOOP_INTERVAL:-60}"
CONNECT_ENDPOINT_HOSTNAME="${CONNECT_ENDPOINT_HOSTNAME:-localhost}"
CONNECT_PORT="${CONNECT_PORT:-8080}"

# Utils
JQ_CMD=$(which jq)
CURL_CMD=$(which curl)
AWK_CMD=$(which awk)

function log() {
  local level=$1
  local message=$2
  $JQ_CMD -c -M -n --arg loglevel $level --arg msg "$message" '{"ts": (now), "loglevel": $loglevel, "message": $msg }'
}

function get_failed_tasks(){
  local rest_endpoint=$1
  local jq_args='-M -c'
  ${CURL_CMD} -s "${rest_endpoint}/connectors?expand=info&expand=status" | \
    $JQ_CMD $jq_args '[map({name: .status.name } +  {tasks: .status.tasks}) |  
                      .[] | {task: ((.tasks[]) + {name: .name})} | 
                      select(.task.state=="FAILED") | {name: .task.name, task_id: .task.id|tostring}]'
}

function validate_replicator_tasks(){
  local URL="http://${CONNECT_ENDPOINT_HOSTNAME}:${CONNECT_PORT}"
  local failed_tasks=$(get_failed_tasks $URL)

  if [[ -z $failed_tasks ]]
  then
    log ERROR "got empty response from replicator at $URL"
    exit 1
  elif [[ $( echo $failed_tasks | $JQ_CMD '. | length' ) -gt 0 ]]
  then
    log WARNING "found failed tasks in replicator: $(echo $failed_tasks | $JQ_CMD '[.[].task_id] | join(",")'), restarting..."

    echo $failed_tasks | $JQ_CMD -c -M '.[]| ("/connectors/"+ .name + "/tasks/" + .task_id + "/restart")' | \
      xargs -I{connector_and_task} $CURL_CMD -s -X POST "$URL"\{connector_and_task\}
  else
    log INFO "could not find any failed tasks in replicator, hooray!!!"
  fi
}

function eventloop(){
  local interval=$1
  log INFO "Starting eventloop with ${interval} interval"
  while true
  do
    validate_replicator_tasks 
    sleep $interval;
  done  
}

function main(){
  eventloop $EVENTLOOP_INTERVAL
}

main