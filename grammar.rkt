#lang brag

ejsexprs: ejsexpr*

ejsexpr: null
  | boolean
  | string
  | number
  | array
  | object

null: "null"

boolean: "true" | "false"

string: DOUBLE-QUOTED-STRING

number: DIGITS | NEGATIVE-DIGITS | DECIMAL-DIGITS | NEGATIVE-DECIMAL-DIGITS

array: "[" ( ejsexpr ( "," ejsexpr )* )* "]"

object: "{" (object-item ("," object-item ) * ) * "}"

object-item: DOUBLE-QUOTED-STRING ":" ejsexpr
