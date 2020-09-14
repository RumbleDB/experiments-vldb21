count(
    for $r in collection("/data/sensors/")
    for $data in $r("data")
    where $data("dataType") eq "TMIN"
    group by $date := $data("date")
    return count($data("station"))
)
