#lang brag
; We parse only URI Template expressions, not full URI Templates
expression: "{" [ operator ] variable-list "}"
operator: op-level2 | op-level3 | op-reserve
op-level2: "+" | "#"
op-level3: "." | "/" | ";" | "?" | "&"
op-reserve: "=" | "," | "!" | "@" | "|"
variable-list: varspec ( "," varspec)*
varspec: varname [ modifier-level4 ]
varname: varchar ([ "." ] varchar)*
varchar: LETTER | "_" | PCT-ENCODED
modifier-level4: prefix | explode
prefix: ":" max-length
max-length: NUMBER
explode: "*"
