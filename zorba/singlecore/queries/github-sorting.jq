jsoniq version "1.0";
import module namespace file = "http://expath.org/ns/file";
let $input :=
    let $dir := "/data/github/"
    for $file in file:list($dir, false, "*.json")
    let $path := $dir || file:directory-separator() || $file
    return parse-json(file:read-text($path))
let $result :=
    for $event in $input
    let $actor := $event.actor.login
    order by $actor
    return $actor
return count($result)
