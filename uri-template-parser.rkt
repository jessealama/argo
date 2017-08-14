#lang brag
uri-template : (literals | expression)*
literals: SAFE-CHAR |  pct-encoded
pct-encoded: "%" hex-digit
hex-digit: digit | hexchar
hexchar: "A" | "B" | "C" | "D" | "E" | "F" | "a" | "b" | "c" | "d" | "e" | "f"
expression: "{" [ operator ] variable-list "}"
operator: op-level2 | op-level3 | op-reserve
op-level2: "+" | "#"
op-level3: "." | "/" | ";" | "?" | "&"
op-reserve: "=" | "," | "!" | "@" | "|"
variable-list: varspec ( "," varspec)*
varspec: varname [ modifier-level4 ]
varname: varchar ("." varchar)*
non-zero-digit: "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
digit: "0" | non-zero-digit
varchar: "A" | "B" | "C" | "D" | "E" | "F" | "G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "a" | "b" | "c" | "d" | "e" | "f" | "g" | "h" | "i" | "j" | "k" | "l" | "m" | "n" | "o" | "p" | "q" | "r" | "s" | "t" | "u" | "v" | "w" | "x" | "y" | "z" | "_" | pct-encoded
modifier-level4: prefix | explode
prefix: ":" max-length
max-length: non-zero-digit ( digit )*
explode: "*"