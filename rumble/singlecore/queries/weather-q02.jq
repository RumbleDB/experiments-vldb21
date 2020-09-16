    for $r_min in json-file("/data/sensors/")
    let $data_min := $r_min.data
    where $data_min.dataType eq "TMIN"
    for $r_max in json-file("/data/sensors/")[$$.data.dataType eq "TMAX"][($$.data.date || $$.data.station) eq ($data_min.date || $data_min.station)]
    let $data_max := $r_max.data
    let $diff := integer($data_max.value) - integer($data_min.value)
    group by $g := 0
    return sum($diff)
