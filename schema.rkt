#lang racket/base

(require json)

(module+ test
  (require rackunit))

(define json-schema-types
  (list "object"
	"array"
	"boolean"
	"integer"
	"number"
	"null"))

(define (json-schema? thing)
  (cond ((not (json-object? thing))
         #f)
        ;; assuming that json-object? ==> hash?
        ((hash-has-key? thing 'type)
         (let ([t (hash-ref thing 'type)])
           (and (string? t)
                (list? (member t json-schema-types)))))
        (else
         #t)))

(module+ test
  (test-case "JSON schema checks")
  ;; Tests to be run with raco test
  (check-false (json-schema? 4))
  (check-false (json-schema? (hasheq "type" "object")))
  (check-true (json-schema? (hasheq 'type "object")))
  (define schema-1/jsexper
    (hasheq
     'type "object"
     'items (hasheq
             'foo (hasheq
                   'type "integer"))
     'additional-items #t))
  (test-case
      "Simple check"
    (check-true (jsexpr? schema-1/jsexper))
    (check-true (json-schema? (hasheq)))))
