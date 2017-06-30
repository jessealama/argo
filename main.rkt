#lang racket/base

(require json)

(module+ test
  (require rackunit))

(define (json-object-has-property? obj prop)
  (hash-has-key? obj prop))

(define (validate-json-object data schema)
  (and (json-object? data)
       (if (hash-has-key? schema 'properties)
           (let ([props (hash-ref schema 'properties)])
             (unless (json-object? props)
               (raise-user-error "Value of the \"properties\" key in the JSON schema is not a JSON object." props))
             (if (hash-has-key? schema 'required)
                 (let ([required (hash-ref schema 'required)])
                   (unless (json-array? required)
                     (raise-user-error "Value of \"required\" is not a JSON array." required))
                   (unless (andmap json-string? required)
                     (raise-user-error "Value of \"required\" contains a non-string."))
                   (if (empty-json-array? x)
                       #t
                       (andmap (lambda (prop)
                                 (json-object-has-property? data prop))
                               data)))
                 #t))
           (if (hash-has-key? schema 'required)
               (let ([required (hash-ref schema 'required)])
                 (unless (json-array? required)
                   (raise-user-error "Value of \"required\" is not a JSON array." required))
                 (unless (andmap json-string? required)
                   (raise-user-error "Value of \"required\" contains a non-string."))
                 (empty-json-array? x)))
           #t)))

(define (validate-json-array data schema)
  (and (list? data)
       (if (hash-has-key? schema 'items)
           (let ([items-schema (hash-ref schema 'items)])
             (unless (json-schema? items-schema)
               (raise-user-error "Schema for an array isn't actually a schema." items-schema))
             (andmap (lambda (x)
                       (valid-wrt-schema? x items-schema))
                     data))
           #t)))

(define (validate-json-string data schema)
  (json-string? data))

(define (validate-json-boolean data schema)
  (json-boolean? data))

(define (validate-json-null data schema)
  (json-null? data))

(define json-schema-validators
  (list (cons "object" validate-json-object)
        (cons "integer" validate-json-integer)
        (cons "array" validate-json-array)
        (cons "null" validate-json-null)
        (cons "boolean" validate-json-boolean)))

(define json-schema-types
  (map car json-schema-validators))

;; assumes that x is alredy a jsexpr? value
(define (json-object? x)
  (hash? x))

;; assumes that x is already a jsexpr? value
(define (json-string? x)
  (string? x))

;; assumes that x is already a jsexpr? value
(define (json-null? x)
  (eq x 'null))

;; assumes that x is already a jsexpr? value
(define (json-boolean? x)
  (boolean? x))

;; assumes that x is already a jsexpr? value
(define (json-array? x)
  (list? x))

;; assumes x is a json-array? value
(define (empty-json-array? x)
  (empty? x))

(module+ test
  (test-case "Basic JSON object check"
    (check-false (json-object? 5))
    (check-false (json-object? #t))
    (check-false (json-object? (list)))
    (check-false (json-object? (hasheq "type" "object")))
    (check-false (json-object? (hasheq 'red 'blue)))
    (check-true (json-object? (hasheq)))
    (check-true (json-object? (hasheq 'type "object")))))

(define (json-array? x)
  (list? x))

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

;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;
;; For your convenience, we have included a LICENSE.txt file, which links to
;; the GNU Lesser General Public License.
;; If you would prefer to use a different license, replace LICENSE.txt with the
;; desired license.
;;
;; Some users like to add a `private/` directory, place auxiliary files there,
;; and require them in `main.rkt`.
;;
;; See the current version of the racket style guide here:
;; http://docs.racket-lang.org/style/index.html

;; Code here

(module+ main
  ;; Main entry point, executed when run with the `racket` executable or DrRacket.
  )
