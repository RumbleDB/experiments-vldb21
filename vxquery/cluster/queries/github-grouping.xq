for $r in collection("/data/github/")
for $type in $r("type")
group by $g := $type
return {"type": $g, "count": count($type)}
