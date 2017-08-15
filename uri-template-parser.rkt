#lang brag
uri-template : (literals | expression)*
literals: LETTER | DIGIT | "." | ":" | "?" | SAFE-CHAR |  pct-encoded
pct-encoded: "%" hex-digit
hex-digit: DIGIT | hexchar
hexchar: "A" | "B" | "C" | "D" | "E" | "F" | "a" | "b" | "c" | "d" | "e" | "f"
expression: "{" [ operator ] variable-list "}"
operator: op-level2 | op-level3 | op-reserve
op-level2: "+" | "#"
op-level3: "." | "/" | ";" | "?" | "&"
op-reserve: "=" | "," | "!" | "@" | "|"
variable-list: varspec ( "," varspec)*
varspec: varname [ modifier-level4 ]
varname: varchar ([ "." ] varchar)*
varchar: LETTER | "_" | pct-encoded
modifier-level4: prefix | explode
prefix: ":" max-length
max-length: NON-ZERO-DIGIT ( DIGIT )*
explode: "*"