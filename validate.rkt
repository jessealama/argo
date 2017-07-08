#lang racket/base

(require json)

(module+ test
  (require rackunit))

(define json-schema-validators
  (list (cons "object" validate-json-object)
        (cons "integer" validate-json-integer)
        (cons "array" validate-json-array)
        (cons "null" validate-json-null)
        (cons "boolean" validate-json-boolean)))

(define json-schema-types
  (map car json-schema-validators))

;; assumes that schema is a json-boolean? value
(define (valid-wrt-schema/boolean? data schema)
  (json-true-value? schema))

;; assumes that schema is a json-object? value
(define (valid-wrt-schema/object? data schema)
  (let ([type (hash-ref schema 'type)])
    (let ([validator-pair (assoc type json-schema-validators)])
      (if (empty? validator-pair)
          (raise-user-error "Unknown JSON Schema type." type)
          (let ([validator (cdr validator-pair)])
            (validator data schema))))))

(define (valid-wrt-schema? data schema)
  (unless (jsexpr? data)
    (raise-user-error "Data is not a jsexpr? value." data))
  (unless (jsexpr? schema)
    (raise-user-error "Schema is not a jsexpr? value." schema))
  (unless (json-schema? schema)
    (raise-user-error "Scheme is not a JSON schema."))
  (cond ((json-boolean? schema)
         (valid-wrt-schema/boolean? data schema))
        ((json-object? schema)
         (valid-wrt-schema/object? data schema))
        (else
         (raise-user-error "Schema should be either a JSON boolean or a JSON object." schema))))

(module+ test)

(module+ main
  ;; Main entry point, executed when run with the `racket` executable or DrRacket.
  )
