#!/usr/bin/env bash
set -e

docker build . -t romilb/data-serving:server
docker tag romilb/data-serving:server public.ecr.aws/cilantro/data-serving:server
docker push public.ecr.aws/cilantro/data-serving:server
