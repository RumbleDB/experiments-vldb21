#!/usr/bin/bash

tempdir=$(mktemp -d)
bucket_name="ingo-json-eu-west-1"
prefix="github/100gb"

while read line;
do
    base="$(echo ${line%.json.gz} | xargs basename)"
    rm "$tempdir/"*
    cp $line "$tempdir/"

    (
        # Unzip
        cd "$tempdir/"
        unpigz "$base.json.gz"
        split "$base.json" \
            --hex-suffixes \
            --line-bytes $((16*10**6)) \
            --additional-suffix=.json "${base}_split_"

        # Split
        for file in *_split_*
        do
            (
                # Zip and upload
                gzip "$file"
                aws s3 cp "$file.gz" "s3://$bucket_name/$prefix/$file.gz"
            ) &
        done
        wait
    )
done
