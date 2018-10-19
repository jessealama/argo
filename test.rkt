#lang racket/base

(require (only-in (file "./json.rkt")
                  has-type?))

(module+ test
  (require rackunit))

(module+ test
  (check-true (has-type? 'null "null"))
  (check-true (has-type? 'null (list "null")))
  (check-true (has-type? 'null (list "string" "null")))
  (check-false (has-type? 'null "string")))
