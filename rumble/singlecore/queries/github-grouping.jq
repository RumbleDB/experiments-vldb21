let $input := json-file("/data/github/")
let $result :=
    for $type in $input.type
    group by $g := $type
    return {"type": $g, "count": count($type)}
return $result
