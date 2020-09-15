count(
    for $r in collection("/data/github/")
    (: "iteration" over single item; work-around for bug in VXQuery :)
    for $type in $r("type")
    return $type
)
