#!/usr/bin/env bash
kubectl delete -f cassandra-seed.yaml --grace-period 0 --force
kubectl delete -f cassandra-server.yaml --grace-period 0 --force
kubectl delete -f cassandra-client-job.yaml --grace-period 0 --force