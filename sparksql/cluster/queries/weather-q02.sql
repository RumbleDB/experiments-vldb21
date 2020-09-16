SELECT SUM(sensors_max.data.value - sensors_min.data.value)
FROM
    sensors AS sensors_min,
    sensors AS sensors_max
WHERE
    sensors_min.data.dataType = "TMIN" AND
    sensors_max.data.dataType = "TMAX" AND
    sensors_min.data.station = sensors_max.data.station AND
    sensors_min.data.date = sensors_max.data.date
