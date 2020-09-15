declare variable $input-path external;
let $input := json-file($input-path)
let $result :=
    for $row in $input
    let $value := double($row.data.value)
    order by $value
    return $value
return count($result)
