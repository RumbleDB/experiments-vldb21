declare variable $input-path external;
let $input := json-file($input-path)
return count($input[$$.data.dataType eq "TMIN" and $$.data.value gt 0])
