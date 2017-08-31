#lang racket/base

(require (only-in (file "util.rkt")
                  file-content/bytes
                  bytes->string
                  complain-and-die))
(require (only-in (file "schema.rkt")
                  json-schema?))
(require (only-in (file "validate.rkt")
                  adheres-to-schema?
                  check-json/schema))

(provide adheres-to-schema?
         json-schema?
         check-json/schema)
