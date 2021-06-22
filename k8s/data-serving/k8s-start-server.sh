#!/usr/bin/env bash
kubectl create -f cassandra-service.yaml
sleep 5
kubectl create -f cassandra-statefulset.yaml