count(
    for $r in json-file("/data/sensors/")
    let $data := $r.data
    where $data.dataType eq "TMIN"
    group by $date := $data.date
    return count($data.station)
)
