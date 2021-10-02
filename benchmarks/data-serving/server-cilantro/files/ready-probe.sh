#!/bin/bash

if [ "$BYPASS_PROBE" = true ]; then
  echo Bypassing probe
  exit 0;
fi

SIGNAL_FILE=/DBREADY.SIGNAL

if [[ -f "$SIGNAL_FILE" ]]; then
    echo "$SIGNAL_FILE exists."
    exit 0;
else
    echo "$SIGNAL_FILE does not exist yet. Please retry."
    exit 1;
fi