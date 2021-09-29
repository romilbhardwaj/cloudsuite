#!/bin/bash
set -e

echo Server IP
hostname --ip-address

echo Envvar CASSANDRA_LISTEN_ADDRESS is ${CASSANDRA_LISTEN_ADDRESS}

if [ -z "$CASSANDRA_SEEDS" ]; then
    NEED_INIT=1
    echo Running Cassandra seed server.
else
    NEED_INIT=0
    echo Running regular Cassandra server.
fi

HOSTNAME=$(hostname -f)

# first arg is `-f` or `--some-option`
if [ "${1:0:1}" = '-' ]; then
	set -- cassandra -f -R "$@"
fi

if [ "$1" = 'cassandra' ] || [ "$1" = 'bash' ]; then
	: ${CASSANDRA_RPC_ADDRESS='0.0.0.0'}

  if [[ -z "${CASSANDRA_LISTEN_ADDRESS}" ]]; then
    : ${CASSANDRA_LISTEN_ADDRESS='auto'}
  fi

	if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
		CASSANDRA_LISTEN_ADDRESS=${POD_IP:-$HOSTNAME}
	else
	  CASSANDRA_LISTEN_ADDRESS=$CASSANDRA_LISTEN_ADDRESS
	fi

	: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

	if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
		CASSANDRA_BROADCAST_ADDRESS=${POD_IP:-$HOSTNAME}
	else
	  CASSANDRA_BROADCAST_ADDRESS=$CASSANDRA_LISTEN_ADDRESS
	fi

	: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

	if [ -n "${CASSANDRA_NAME:+1}" ]; then
		: ${CASSANDRA_SEEDS:="cassandra"}
	fi
	: ${CASSANDRA_SEEDS:="$CASSANDRA_BROADCAST_ADDRESS"}
	
	sed -ri 's/(- seeds:) "127.0.0.1"/\1 "'"$CASSANDRA_SEEDS"'"/' "$CASSANDRA_CONFIG/cassandra.yaml"

	for yaml in \
		broadcast_address \
		broadcast_rpc_address \
		cluster_name \
		endpoint_snitch \
		listen_address \
		num_tokens \
		rpc_address \
		start_rpc \
	; do
		var="CASSANDRA_${yaml^^}"
		val="${!var}"
		if [ "$val" ]; then
			sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$CASSANDRA_CONFIG/cassandra.yaml"
		fi
	done

	for rackdc in dc rack; do
		var="CASSANDRA_${rackdc^^}"
		val="${!var}"
		if [ "$val" ]; then
			sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CASSANDRA_CONFIG/cassandra-rackdc.properties"
		fi
	done
fi

echo Using CASSANDRA_LISTEN_ADDRESS ${CASSANDRA_LISTEN_ADDRESS}
echo Using CASSANDRA_BROADCAST_ADDRESS ${CASSANDRA_BROADCAST_ADDRESS}

exec "$@"
