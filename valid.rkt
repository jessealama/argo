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

(define (valid-wrt-schema? data schema)
  (unless (jsexpr? data)
    (raise-user-error "Data is not a jsexpr? value." data))
  (unless (jsexpr? schema)
    (raise-user-error "Schema is not a jsexpr? value." schema))
  (unless (json-schema? schema)
    (raise-user-erro "Scheme is not a JSON schema."))
  ;; assuming that json-schema? ==> hash?
  (cond ((not (hash-has-ref schema 'type))
         #t)
        (else
         (let ([type (hash-ref schema 'type)])
           (let ([validator-pair (assoc type json-schema-validators)])
             (if (empty? validator-pair)
                 (raise-user-error "Unknown JSON Schema type." type)
                 (let ([validator (cdr validator-pair)])
                   (validator data schema))))))))

(module+ main
  ;; Main entry point, executed when run with the `racket` executable or DrRacket.
  )
