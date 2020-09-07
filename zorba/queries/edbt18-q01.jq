jsoniq version "1.0";
import module namespace file = "http://expath.org/ns/file";
let $data :=
    let $dir := "/data/sensors/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || file:directory-separator() || $file
    return parse-json(file:read-text($path))
let $result :=
    for $row in $data
    let $data := $row.data
    where $data.dataType eq "TMIN"
    group by $date := $data.date
    return count($data.station)
return count($result)
