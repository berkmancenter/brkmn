#!/bin/bash

docker build -t brkmn -f docker/Dockerfile --no-cache .
image_id=$(docker images | grep brkmn | awk '{print $3}' | tail -n 1)
docker tag $image_id berkmancenter/brkmn:$1
docker tag $image_id berkmancenter/brkmn:latest
docker push berkmancenter/brkmn:$1
docker push berkmancenter/brkmn:latest
