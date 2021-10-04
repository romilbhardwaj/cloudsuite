#!/usr/bin/env bash
set -e

docker build . -t romilb/data-serving:client
docker tag romilb/data-serving:client public.ecr.aws/cilantro/data-serving:client
docker push public.ecr.aws/cilantro/data-serving:client
