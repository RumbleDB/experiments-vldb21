declare variable $input-path external;
let $input := json-file($input-path)
return count($input)
