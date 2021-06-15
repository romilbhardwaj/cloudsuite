#!/usr/bin/env bash

NUM_REPLICAS=1
# Create the network
docker network create serving_network

# Run the seed serving container
docker run -d --name cassandra-server-seed --net serving_network cloudsuite/data-serving:server

# Run server replicas
REPLICA_STR=""
echo Creating ${NUM_REPLICAS} replicas.
for i in $(seq ${NUM_REPLICAS}); do
  docker run -d --name cassandra-server${i} --net serving_network -e CASSANDRA_SEEDS=cassandra-server-seed cloudsuite/data-serving:server
  REPLICA_STR+=cassandra-server${i},
done
# Remove trailing comma
REPLICA_STR=${REPLICA_STR: : -1}

# Wait for containers to start and complete init
sleep 30
echo Created ${REPLICA_STR}.

# Run client
docker run --name cassandra-client --net serving_network cloudsuite/data-serving:client "cassandra-server-seed,"

echo DONE. Remember to run docker-clean.sh to clean up running containers.