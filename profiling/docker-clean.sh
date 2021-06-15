#!/usr/bin/env bash

# Removes running all running docker containers
docker kill $(docker ps -q)
docker rm $(docker ps -a -q)