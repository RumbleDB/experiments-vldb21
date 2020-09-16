WITH NumberOfMinsPerDay AS (
    SELECT COUNT(*)
    FROM sensors
    WHERE data.dataType = "TMIN"
    GROUP BY date(data.date)
)
SELECT COUNT(*) FROM NumberOfMinsPerDay
