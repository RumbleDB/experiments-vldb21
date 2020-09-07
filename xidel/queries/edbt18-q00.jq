import module namespace file = "http://expath.org/ns/file";
let $data :=
    let $dir := "/data/sensors/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || "/" || $file
    return jn:json-doc($path)
let $result :=
    for $row in $data
    let $data := $row.data
    let $datetime := dateTime($data.date)
    where year-from-dateTime($datetime) ge 2003
        and month-from-dateTime($datetime) eq 12
        and day-from-dateTime($datetime) eq 25
    return $data
return count($result)
