#!/usr/bin/env bash
set -e

docker build . -t public.ecr.aws/cilantro/data-analytics:4.0
docker push public.ecr.aws/cilantro/data-analytics:4.0
