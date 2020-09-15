declare variable $input-path external;
let $input := json-file($input-path)
let $result :=
    for $type in $input.type
    group by $g := $type
    return {"type": $g, "count": count($type)}
return $result
