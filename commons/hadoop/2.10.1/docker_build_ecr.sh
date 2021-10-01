#!/usr/bin/env bash
set -e

docker build . -t public.ecr.aws/cilantro/hadoop:2.10.1
docker push public.ecr.aws/cilantro/hadoop:2.10.1
