#!/bin/bash

if [[ $(JAVA_HOME=/usr/lib/jvm/adoptopenjdk-8-hotspot-amd64/ nodetool status | grep $POD_IP) == *"UN"* ]]; then
  if [[ $DEBUG ]]; then
    echo "UN";
  fi
  exit 0;
else
  if [[ $DEBUG ]]; then
    echo "Not Up";
  fi
  exit 1;
fi