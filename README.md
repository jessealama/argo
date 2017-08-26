Argo: Go forth and validate your JSON
====

Argo is a JSON Schema validator for Racket. It aims to adhere to version 6 of the JSON Schema specification.

The main function is `adheres-to-schema?`. It takes two arguments, both supposed to be [jsexpr?](https://docs.racket-lang.org/json/index.html?q=jsexpr%3F#%28def._%28%28lib._json%2Fmain..rkt%29._jsexpr~3f%29%29) values. The first is the data to validate; the second is the schema. Returns `#t` or `#f` if the data adheres to the given schema.

Argo adheres to version 6 of [JSON Schema](http://json-schema.org). This version is fairly new (released 2017-04-15); a lot of the JSON Schemas out there on the internet are version 4.

Bug reports and feature requests are welcome; reach me at [`jesse@lisp.sh`](mailto:jesse@lisp.sh).
