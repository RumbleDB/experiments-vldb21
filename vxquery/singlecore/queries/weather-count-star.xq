count(
    for $r in collection("/data/sensors/")
    (: "iteration" over single item; work-around for bug in VXQuery :)
    for $data in $r("data")
    return $data
)

