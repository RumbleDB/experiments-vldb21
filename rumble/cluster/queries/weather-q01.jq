declare variable $input-path external;
count(
    for $r in json-file($input-path)
    let $data := $r.data
    where $data.dataType eq "TMIN"
    group by $date := $data.date
    return count($data.station)
)
