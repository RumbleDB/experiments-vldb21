import module namespace file = "http://expath.org/ns/file";
let $data :=
    let $dir := "/data/sensors/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || "/" || $file
    return jn:json-doc($path)
let $result :=
    for $row in $data
    where $row.data.dataType eq "TMIN" and $row.data.value gt 0
    return $row
return count($result)
