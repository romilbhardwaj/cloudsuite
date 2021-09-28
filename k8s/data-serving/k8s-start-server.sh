#!/usr/bin/env bash
kubectl create -f cassandra-seed.yaml
sleep 5
kubectl create -f cassandra-server.yaml