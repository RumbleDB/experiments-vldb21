let $data := json-file("/data/sensors/")
return count($data[$$.data.dataType eq "TMIN" and $$.data.value gt 0])
