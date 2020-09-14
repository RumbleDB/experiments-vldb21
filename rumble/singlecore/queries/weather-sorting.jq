let $data := json-file("/data/sensors/")
let $result :=
    for $row in $data
    let $value := double($row.data.value)
    order by $value
    return $value
return count($result)
