let $data := json-file("/data/sensors/")
for $row in $data
group by $g := $row.data.dataType
return {"dataType": $g, "count": count($row)}
