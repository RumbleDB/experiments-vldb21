#!/bin/bash

BUCKETNAME="ingo-json-eu-west-1"
PREFIX="github/full"

yearmonths=("$@")

for yearmonth in ${yearmonths[*]}
do
    year=${yearmonth%-*}
    month=${yearmonth#*-}
    echo "Downloading $year/$month..."

    for day in {01..31}
    do
        for hour in {0..23}
        do
            (
                # Download
                url="https://data.gharchive.org/$year-$month-$day-$hour.json.gz"
                filename="$year-$month-$day-$hour.json.gz"
                dirname="$year/$month/"
                outputname="$dirname/$filename"
                echo "Downloading $filename..."

                mkdir -p $dirname
                wget "$url" -nc -qO "$outputname"

                # Uncompress
                echo "Decompressing $filename..."
                gunzip "$outputname"
                true
            ) &
        done
        wait
    done

    # Recombine into large files
    outputbase="$year/$month/$year-$month"
    echo "Recombining $outputbase-*..."
    for file in "$outputbase-"*
    do
        cat "$file"
        rm "$file"
    done | split /dev/stdin "$outputbase-" \
                --line-bytes $((2**30)) \
                --suffix-length 3 \
                --additional-suffix=.json

    # Compress again and upload
    for file in "$outputbase-"*
    do
        (
            echo "Compressing $file..."
            gzip "$file"
            gzfile="$file.gz"
            echo "Uploading $gzfile..."
            aws s3 cp "$gzfile" "s3://$BUCKETNAME/$PREFIX/$(basename $gzfile)" && rm "$gzfile"
        ) &
    done
    wait
    echo "Done with $outputbase-*."
done
