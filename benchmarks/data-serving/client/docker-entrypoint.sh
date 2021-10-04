#!/bin/bash
# Before running this script make sure to set/UNSET (i.e. remove the variable) the following envvars:
# NOINITDB : To skip db initialization
# USEK8S : To use k8s to resolve the IPs for the service name in $1.

echo server\'s IP is $1
echo output dir is $2

DEFAULT_RECORDCOUNT=10000
DEFAULT_OPERATIONCOUNT=1000
DEFAULT_THREADCOUNT=16

if [ -z "$RECORDCOUNT" ]; then
    RECORDCOUNT=${DEFAULT_RECORDCOUNT}
fi

if [ -z "$OPERATIONCOUNT" ]; then
    OPERATIONCOUNT=${DEFAULT_OPERATIONCOUNT}
fi

if [ -z "$THREADCOUNT" ]; then
    THREADCOUNT=${DEFAULT_THREADCOUNT}
fi

if [ ! -z "$USEK8S" ]; then
    K8SARGS="--use-k8s"
else
    K8SARGS=""
fi

# If NOINITDB envvar is present,  do not initialize the DB and populate tables
if [ ! -z "$NOINITDB" ]; then
  echo '======================================================'
  echo 'Envvar NOINITDB found! Not initializing database.'
  echo '======================================================'
else
  echo '======================================================'
  echo 'Creating a usertable for the seed server'
  echo '======================================================'

  first_server=$(cut -d',' -f1 <<< "$1")

  exit=0
  while [ $exit -eq 0 ]; do
      set +e
      cqlsh -f /setup_tables.txt $first_server
      if [[ "$?" -eq 0 ]]; then
          exit=1
      else
          echo 'Cannot connect to the seed server. Trying again...'
      fi
      set -e
      sleep 5
  done


  echo '======================================================'
  echo 'Keyspace usertable was created, Loading data.'
  echo '======================================================'

  /ycsb/bin/ycsb load cassandra-cql -p readproportion=1 -p updateproportion=0 -p hosts=$1 -P /ycsb/workloads/workloada -p recordcount=$RECORDCOUNT

  echo '======================================================'
  echo 'Data load done!'
  echo '======================================================'
fi

echo '======================================================'
echo 'Running benchmark now!'
echo '======================================================'
python ycsb_loop_driver.py --out-dir $2 $K8SARGS --server-ips $1 --recordcount $RECORDCOUNT --operationcount $OPERATIONCOUNT --threadcount $THREADCOUNT --target $TARGET

# echo "/ycsb/bin/ycsb run cassandra-cql -p readproportion=1 -p updateproportion=0 -p hosts=$1 -P /ycsb/workloads/workloada -p hdrhistogram.percentiles=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99 $THREADCOUNT $OPERATIONCOUNT $RECORDCOUNT"
# python /ycsb_loop_driver.py --cmd "/ycsb/bin/ycsb run cassandra-cql -p readproportion=1 -p updateproportion=0 -p hosts=$1 -P /ycsb/workloads/workloada -p hdrhistogram.percentiles=1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99 $THREADCOUNT $OPERATIONCOUNT $RECORDCOUNT" --out-dir $2
