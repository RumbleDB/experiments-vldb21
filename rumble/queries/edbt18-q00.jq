let $data := json-file("/data/sensors/")
let $result :=
    for $row in $data
    let $data := $row.data
    let $datetime := dateTime($data.date)
    where year-from-dateTime($datetime) ge 2003
        and month-from-dateTime($datetime) eq 12
        and day-from-dateTime($datetime) eq 25
    return $data
return count($result)
