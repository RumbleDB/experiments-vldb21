#!/usr/bin/bash

SCRIPT_PATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

VXQ=/home/muellein/git/vxquery/vxquery-cli/target/appassembler/bin/vxq
TMPDIR=/var/muellein/tmp

while read line
do
    base="$(basename "$line")"
    outfile="$(dirname "$line")/$base".jsonl

    echo "Creating '$outfile'..."
    if [[ -f "$outfile" ]]
    then
        echo "  Already exists. Skipping..."
        continue
    fi

    cp -r "$line" "$TMPDIR"/
    cat - > "$TMPDIR"/convert.xq <<-EOF
		let \$sensor_collection := "$TMPDIR/$base/"
		for \$d in collection(\$sensor_collection)/dataCollection/data
		return {
		    "data": {
		        "date":     data(\$d/date),
		        "dataType": data(\$d/dataType),
		        "station":  data(\$d/station),
		        "value":    xs:integer(\$d/value)
		    }
		}
		EOF
    sh "$VXQ" -result-file "$outfile" "$TMPDIR"/convert.xq -timing
    rm -rf "$TMPDIR/$base"
done
