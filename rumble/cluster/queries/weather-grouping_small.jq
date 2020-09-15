declare variable $input-path external;
let $input := json-file($input-path)
for $row in $input
group by $g := $row.data.dataType
return {"dataType": $g, "count": count($row)}
