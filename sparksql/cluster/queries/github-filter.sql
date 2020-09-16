SELECT COUNT(payload.release.author.login)
FROM github
WHERE type = "ReleaseEvent" AND
    payload.release.prerelease = TRUE
