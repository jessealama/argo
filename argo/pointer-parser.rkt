#lang brag
json-pointer : ("/" reference-token)*
reference-token : (NEGATED-0 | NEGATED-1 | UNESCAPED)*
