#!/bin/bash

for line in $(cat image-mirror.csv); do
    IFS=',' read -a fields <<< "$line"
    FROM_IMAGE=${fields[0]}
    TO_IMAGE=${fields[1]}

    docker pull ${FROM_IMAGE}
    docker tag ${FROM_IMAGE} ${TO_IMAGE}
    docker push ${TO_IMAGE}
done
