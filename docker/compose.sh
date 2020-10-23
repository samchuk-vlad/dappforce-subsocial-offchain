#!/bin/bash
set -e

pushd . > /dev/null

# The following line ensure we run from the script folder
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
eval cd $DIR

UTILS_ONLY=false
UTILS=" postgres elasticsearch ipfs-cluster pgadmin graphql-engine"
# UTILS=" postgres pgadmin graphql-engine"

# Generated new IPFS Cluster secret in case the 'ipfs-data' directory was deleted
export CLUSTER_SECRET=$(od  -vN 32 -An -tx1 /dev/urandom | tr -d ' \n')

case $1 in
  --down)
    time docker-compose kill
    if [[ $2 == 'clean' ]]; then
      echo "Cleaning volumes..."
      docker-compose down -v
    fi
    exit 0
    ;;
  --utils)
    UTILS_ONLY=true
    ;;
  --pgadmin)
    UTILS_ONLY=true
    UTILS=" pgadmin"
    ;;
  -?*)
    printf "Invalid argument provided.\n\nExamples:\n"
    printf "Start all:\n./compose.sh\n\n"
    printf "Start services without offchain itself:\n./compose.sh --utils\n\n"
    printf "Stop all:\n./compose.sh --down\n\n"
    printf "Clean all:\n./compose.sh --down clean\n"

    exit 1
    ;;
  --)
    UTILS_ONLY=false
    ;;
esac

ES_NODE_URL='http://127.0.0.1:9200'
IPFS_NODE_URL='http://127.0.0.1:8080'

time (
  printf "Starting offchain in background, hang on!\n\n"

  if $UTILS_ONLY; then
    docker-compose up -d $UTILS
  else
    docker-compose up -d

    if [[ $UTILS =~ 'elasticsearch' ]]; then
      eval docker stop subsocial-offchain &> /dev/null
      
      printf "\nStarting Elasticsearch...\n"
      until curl -s $ES_NODE_URL > /dev/null; do
        sleep 2
      done
      docker-compose up -d offchain
    fi
  fi

  if [[ $UTILS =~ 'ipfs' ]]; then
    printf "\nWaiting until IPFS is ready...\n"
    until curl -s --X GET ${IPFS_NODE_URL}'/api/v0/version' > /dev/null
    do
      sleep 1
    done
    docker exec subsocial-ipfs-node \
      ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
    docker exec subsocial-ipfs-node \
      ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET"]'
    docker exec subsocial-ipfs-node ipfs bootstrap rm --all &> /dev/null

    printf "Restarting "
    docker restart subsocial-ipfs-node
  fi

  # TODO: Add initial peer as the only one trusted
)

echo "Containers are ready."

popd > /dev/null
