#!/bin/bash

docker stack deploy --with-registry-auth --detach=true -c compose.yml microservices-stack
