#!/bin/bash

BUCKETNAME="ingo-json-eu-west-1"
PREFIX="github/sample"

yearmonths=("$@")

for yearmonth in ${yearmonths[*]}
do
    year=${yearmonth%-*}
    month=${yearmonth#*-}
    echo "Downloading $year/$month..."

    for day in 01 15
    do
        for hour in 0 6 12 18
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
            ) &
        done
        wait
    done

    # Recombine into large files
    outputbase="$year/$month/$year-$month"
    echo "Recombining $outputbase-*..."
    for file in "$outputbase-"*
    do
        unpigz -c "$file" | head -n6250
        rm "$file"
    done > "$outputbase.json"

    # Compress
    echo "Compressing $outputbase.json..."
    pigz "$outputbase.json"
    echo "Done with $outputbase.json.gz."
done
