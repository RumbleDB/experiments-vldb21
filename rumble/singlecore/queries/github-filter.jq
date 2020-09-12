let $input := json-file("/data/github/")
let $result :=
    for $event in $input
    where $event.type eq "ReleaseEvent"
        and $event.payload.release.prerelease
    return $event.payload.release.author.login
return count($result)
