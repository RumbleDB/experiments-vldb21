#!/usr/bin/bash

for dir in weather-*
do
    (
        cd $dir/sensors && \
        split data.json -n l/100 part_ --additional-suffix .json
    )
done
