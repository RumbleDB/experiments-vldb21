    for $r_min in json-file("/data/sensors/")
    let $data_min := $r_min.data
    where $data_min.dataType eq "TMIN"
    for $r_max in json-file("/data/sensors/")[$$.data.date eq $data_min.date]
    let $data_max := $r_max.data
    where $data_max.dataType eq "TMAX"
    where $data_min.station eq $data_max.station
    let $diff := integer($data_max.value) - integer($data_min.value)
    group by $g := 0
    return sum($diff)
