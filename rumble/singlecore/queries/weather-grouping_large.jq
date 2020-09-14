let $data := json-file("/data/sensors/")
let $result :=
    for $row in $data
    group by $g := $row.data.date
    return {"date": $g, "count": count($row)}
return count($result)
