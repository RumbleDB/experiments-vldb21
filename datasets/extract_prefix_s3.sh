#!/usr/bin/bash

BUCKETNAME="ingo-json-eu-west-1"
INPUTPREFIX="github/full"
OUTPUTPREFIX="github/samples"

# Read CLI parameters
num_mega_bytes="$1"
shift
files=("$@")

# Compute number of bytes to extract per file
num_bytes=$(($num_mega_bytes * 10**6))
num_files=${#files[*]}
num_bytes_per_file=$((($num_bytes + $num_files - 1)/$num_files))
outputprefix="$OUTPUTPREFIX/${num_mega_bytes}mb"

# Downloads one file, extracts prefix, uploads again
function extract_one {(
    bucketname="$1"
    inputprefix="$2"
    outputprefix="$3"
    num_bytes="$4"
    gzfile="$5"

    jsonfile="${gzfile%.gz}"
    aws s3 cp "s3://$bucketname/$inputprefix/$gzfile" .

    zcat "$gzfile" | awk -v n="$num_bytes" 'c>=n{exit} {c+=length()+1} 1' > "$jsonfile"
    rm "$gzfile"

    aws s3 cp "$jsonfile" "s3://$bucketname/${outputprefix}/$jsonfile"
    rm "$jsonfile"
)}

# Run on all input files using 'parallel'
export -f extract_one
for file in ${files[*]}
do
    echo "$file"
done | xargs -n1 -P$(nproc) -I'{}' bash -c "extract_one '$BUCKETNAME' '$INPUTPREFIX' '$outputprefix' '$num_bytes_per_file' '{}'"
