#lang racket/base

(require (only-in json
                  jsexpr?)
         (only-in sugar
                  members-unique?)

         (only-in (file "json.rkt")
                  json-boolean?
                  json-object?
                  json-string?
                  json-array?
                  json-object-has-property?
                  json-object-property-value
                  json-object-properties)
         (only-in (file "util.rkt")
                  intersection))

(module+ test
  (require rackunit))

(define json-schema-types
  (list "object"
	"array"
	"boolean"
	"integer"
	"number"
	"null"))

(define (json-schema-type? thing)
  (list? (member thing json-schema-types)))

(define (acceptable-value-for-type value)
  (cond ((json-string? value)
         (json-schema-type? value))
        ((json-array? value)
         (and (members-unique? value)
              (andmap json-schema-type? value)))
        (else
         #f)))

(define json-object-validators
  (hasheq 'type acceptable-value-for-type))

(define json-object-keywords
  (hash-keys json-object-validators))

(define (json-schema? thing)
  (cond ((not (jsexpr? thing))
         #f)
        ((json-boolean? thing)
         #t)
        ((json-object? thing)
         (let ([properties (json-object-properties thing)])
           (let ([checkable (intersection properties json-object-keywords)])
             (andmap (lambda (keyword)
                       ((hash-ref json-object-validators keyword)
                        (hash-ref thing keyword)))
                     checkable))))
        (else
         #f)))

(module+ test

  (test-case "Silly JSON schema type checks"
    (check-false (json-schema? 4)))

  (test-case "Boolean JSON schema checks"
    (check-true (json-schema? #t))
    (check-true (json-schema? #f)))

  (test-case "JSON schema checks")
  (check-false (json-schema? (hasheq "type" "object")))
  (check-false (json-schema? (hasheq 'type #f)))
  (let ([js (hasheq 'type "object")])
    (check-true (json-object? js))
    (check-true (json-object-has-property? js 'type))
    (check-true (json-string? (json-object-property-value js 'type)))
    (check-true (json-schema? js)))

  (check-false (json-schema? (hasheq 'type "foo")))

  ;; funky edge case: empty array as type
  (check-true (json-schema? (hasheq 'type
                                    (list))))

  (check-false (json-schema? (hasheq 'type
                                     (list "foo"))))

  ;; single correct value
  (check-true (json-schema? (hasheq 'type
                                    (list "object"))))

  ;; typo
  (check-false (json-schema? (hasheq 'type
                                     (list "objet"))))

  ;; two legimate values
  (check-true (json-schema? (hasheq 'type
                                    (list "object" "integer"))))

  ;; extreme case: all the types
  (check-true (json-schema? (hasheq 'type
                                    json-schema-types)))

  ;; duplicate values (though each, separately, is valid)
  (check-false (json-schema? (hasheq 'type
                                     (list "object" "number" "object"))))

  ;; bogus value along with legit value
  (check-false (json-schema? (hasheq 'type
                                     (list "number" "real"))))

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
