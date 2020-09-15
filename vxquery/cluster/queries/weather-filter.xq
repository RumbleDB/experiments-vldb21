count(
    for $r in collection("/data/sensors/")
    (: "iteration" over single item; work-around for bug in VXQuery :)
    for $data in $r("data")
    where $data("dataType") eq "TMIN" and $data("value") gt 0
    return $data
)
