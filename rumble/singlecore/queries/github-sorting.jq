let $input := json-file("/data/github/")
let $result :=
    for $event in $input
    let $actor := $event.actor.login
    order by $actor
    return $actor
return count($result)
