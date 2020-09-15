declare variable $input-path external;
let $input := json-file($input-path)
let $result :=
    for $event in $input
    let $actor := $event.actor.login
    order by $actor
    return $actor
return count($result)
