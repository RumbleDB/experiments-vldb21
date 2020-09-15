declare variable $input-path external;
let $input := json-file($input-path)
let $result :=
    for $row in $input
    group by $g := $row.data.date
    return {"date": $g, "count": count($row)}
return count($result)
