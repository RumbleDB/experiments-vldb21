count(
    for $r in collection("/data/github/")
    where $r("type") eq "ReleaseEvent"
        and $r("payload")("release")("prerelease")
    return $r("payload")("release")("author")("login")
)
