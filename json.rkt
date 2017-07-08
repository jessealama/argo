#lang racket/base

(require json)

(require (only-in racket/list
                  empty?))

(module+ test
  (require rackunit))

;; assumes that x is alredy a jsexpr? value
(define (json-object? x)
  (hash? x))

(provide json-object?)

;; assumes that x is already a jsexpr? value
(define (json-string? x)
  (string? x))

(provide json-string?)

;; assumes that x is already a jsexpr? value
(define (json-null? x)
  (eq? x 'null))

(provide json-null?)

;; assumes that x is already a jsexpr? value
(define (json-boolean? x)
  (boolean? x))

(provide json-boolean?)

;; assumes that x is already a jsexpr? value
(define (json-array? x)
  (list? x))

(provide json-array?)

(module+ test
  (check-true (json-array? (list)))
  (check-false (json-array? (hasheq))))

;; assumes that x is already a jsexpr? value
(define (json-number? x)
  (real? x))

(module+ test
  (check-true (json-number? 4))
  (check-false (json-number? #t))
  (check-false (json-number? (hasheq)))
  (check-true (json-number? -4.5))
  (check-true (json-number? 3.141592653589793238462643383279)))

(define (json-integer? x)
  (integer? x))

(module+ test
  (test-case "JSON integers"
     (check-true (json-integer? 4))
     (check-true (json-integer? -4))
     (check-true (json-integer? 4.0))
     (check-false (json-integer? 4.1))
     (check-false (json-integer? #t))))

(define (json-object-has-property? obj prop)
  (hash-has-key? obj prop))

(provide json-object-has-property?)

(define (json-object-property-value obj prop)
  (hash-ref obj prop))

(provide json-object-property-value)

;; assumes x is a json-array? value
(define (empty-json-array? x)
  (empty? x))

(provide empty-json-array?)

(module+ test
  (test-case "Basic JSON object check"
    (check-false (json-object? 5))
    (check-false (json-object? #t))
    (check-false (json-object? (list)))
    (check-true (json-object? (hasheq)))
    (check-true (json-object? (hasheq 'type "object")))))

(define (json-object-properties obj)
  (hash-keys obj))

(provide json-object-properties)
