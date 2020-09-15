count(
    for $r in collection("/data/sensors/")
    for $data in $r("data")
    let $datetime := xs:dateTime($data("date"))
    let $year := fn:year-from-dateTime($datetime)
    where fn:year-from-dateTime($datetime) ge 2003
        and fn:month-from-dateTime($datetime) eq 12
        and fn:day-from-dateTime($datetime) eq 25
    return $data
)
