#!/bin/bash

SIP=127.0.0.1

echo server\'s IP is ${SIP}

if [ ! -z "$RECORDCOUNT" ]; then
    echo RECORDCOUNT is ${RECORDCOUNT}
else
    echo RECORDCOUNT not set. Using default 1000.
    RECORDCOUNT=1000
fi
RECORDCOUNT="-p recordcount=$RECORDCOUNT"

echo '======================================================'
echo 'Attempting to create  a usertable for the seed server'
echo '======================================================'

exit=0
while [ $exit -eq 0 ]; do
    set +e
    cqlsh -f /scripts/setup_tables.txt ${SIP}
    if [[ "$?" -eq 0 ]]; then
        exit=1
    else
        echo 'Cannot connect to the seed server. Trying again...'
    fi
    set -e
    sleep 5
done


echo '======================================================'
echo Keyspace usertable was created, loading data now with ${RECORDCOUNT}
echo '======================================================'

/ycsb/bin/ycsb load cassandra-cql -p readproportion=1 -p updateproportion=0 -p hosts=$SIP -P /ycsb/workloads/workloada $RECORDCOUNT

echo '======================================================'
echo 'Data load done! Creating signal file'
echo '======================================================'

# Create a signal file used by the readiness probe in k8s.
echo "DONE" > /DBREADY.SIGNAL