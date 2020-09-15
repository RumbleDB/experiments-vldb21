declare variable $input-path external;
let $input := json-file($input-path)
let $result :=
    for $row in $input
    let $data := $row.data
    let $datetime := dateTime($data.date)
    where year-from-dateTime($datetime) ge 2003
        and month-from-dateTime($datetime) eq 12
        and day-from-dateTime($datetime) eq 25
    return $data
return count($result)
