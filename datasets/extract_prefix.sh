#!/bin/bash

# Read CLI parameters
num_bytes="$1"
shift
files=("$@")

# Returns lines until num_bytes or more bytes have been returned
function extract_lines {(
    num_bytes=$1
    awk -v n="$num_bytes" 'c>=n{exit} {c+=length()+1} 1'
)}

# Iterate over files, extracting a similar number of bytes from each
num_files=${#files[*]}
num_bytes_per_file=$((($num_bytes + $num_files - 1)/$num_files))

for file in ${files[*]}
do
    zcat "$file" | extract_lines $num_bytes_per_file
done | extract_lines $num_bytes
