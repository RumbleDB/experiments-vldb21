count(
    for $r in collection("/data/github/")
    for $actor in $r
    let $login := $actor("login")
    order by $login
    return $login
)
