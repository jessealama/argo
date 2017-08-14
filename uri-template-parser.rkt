#lang brag
uri-template : (literals | expression)*
literals: LETTER | SAFE-CHAR |  pct-encoded
pct-encoded: "%" hex-digit
hex-digit: NUMERAL | hexchar
hexchar: "A" | "B" | "C" | "D" | "E" | "F" | "a" | "b" | "c" | "d" | "e" | "f"
expression: "{" [ operator ] variable-list "}"
operator: op-level2 | op-level3 | op-reserve
op-level2: "+" | "#"
op-level3: "." | "/" | ";" | "?" | "&"
op-reserve: "=" | "," | "!" | "@" | "|"
variable-list: varspec ( "," varspec)*
varspec: varname [ modifier-level4 ]
varname: varchar ([ "." ] varchar)*
non-zero-digit: "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
varchar: LETTER | "_" | pct-encoded
modifier-level4: prefix | explode
prefix: ":" max-length
max-length: non-zero-digit ( NUMERAL )*
explode: "*"