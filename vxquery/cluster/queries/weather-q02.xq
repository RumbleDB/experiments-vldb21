(: avg ( :)
for $r_min in collection("/data/sensors/")
for $data_min in $r_min("data")
for $r_max in collection("/data/sensors/")
for $data_max in $r_max("data")
where $data_min("station") eq $data_max("station")
    and $data_min("date") eq $data_max("date")
    and $data_min("dataType") eq "TMIN"
    and $data_max("dataType") eq "TMAX"
(: calling avg() or any other aggregation function on the result of the outer
   FLWOR doesn't work due to a bug, so we group by a single group to get the
   same effect. :)
group by $g := 0
(: The following line should produce the correct result, ...
      return avg(xs:integer($data_max("value")) - xs:integer($data_min("value"))) div 10
   ...however,
   (1) computing a difference does not work due to a bug (neither in place nor
       with a new variable),
   (2) using the average instead of count does not work due to a bug,
   (3) dividing the result by 10 does not work due to a bug:)
return count(xs:integer($data_min("value")))
(: ) div 10 :)
