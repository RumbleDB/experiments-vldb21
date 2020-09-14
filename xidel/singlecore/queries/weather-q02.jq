import module namespace file = "http://expath.org/ns/file";
let $data :=
    let $dir := "/data/sensors/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || "/" || $file
    return jn:json-doc($path)
let $result :=
    for $r_min in $data
    let $data_min := $r_min.data
    where $data_min.dataType eq "TMIN"
    for $r_max in $data
    let $data_max := $r_max.data
    where $data_max.dataType eq "TMAX"
    where $data_min.station eq $data_max.station
        and $data_min.date eq $data_max.date
    return integer($data_max.value) - integer($data_min.value)
return avg($result) div 10
