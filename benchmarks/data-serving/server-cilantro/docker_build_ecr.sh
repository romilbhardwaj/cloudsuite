#!/usr/bin/env bash
set -e

docker build . -t public.ecr.aws/cilantro/data-serving:server-horz
docker push public.ecr.aws/cilantro/data-serving:server-horz
