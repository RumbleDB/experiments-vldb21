SELECT from_json(actor, "login string")
FROM github
ORDER BY from_json(actor, "login string")
LIMIT 10
