#!/usr/bin/env bash
kubectl delete -f cassandra-statefulset.yaml --grace-period 0 --force
kubectl delete -f cassandra-service.yaml --grace-period 0 --force
kubectl delete -f cassandra-client-job.yaml --grace-period 0 --force