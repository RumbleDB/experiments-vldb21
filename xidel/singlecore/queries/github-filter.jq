import module namespace file = "http://expath.org/ns/file";
let $input :=
    let $dir := "/data/github/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || "/" || $file
    return jn:json-doc($path)
let $result :=
    for $event in $input
    where $event.type eq "ReleaseEvent"
        and $event.payload.release.prerelease
    return $event.payload.release.author.login
return count($result)
