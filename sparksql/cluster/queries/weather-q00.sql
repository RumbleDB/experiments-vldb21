SELECT COUNT(*)
FROM sensors
WHERE year(date(data.date)) = 2003 AND
    month(date(data.date)) = 12 AND
    day(date(data.date)) = 25
