#lang racket/base

(require json)

(require (only-in racket/list
                  empty?))

(module+ test
  (require rackunit))

;; assumes that x is alredy a jsexpr? value
(define (json-object? x)
  (hash? x))

;; assumes that x is already a jsexpr? value
(define (json-string? x)
  (string? x))

;; assumes that x is already a jsexpr? value
(define (json-null? x)
  (eq? x 'null))

;; assumes that x is already a jsexpr? value
(define (json-boolean? x)
  (boolean? x))

;; assumes that x is already a jsexpr? value
(define (json-array? x)
  (list? x))

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

;; assumes x is a json-array? value
(define (empty-json-array? x)
  (empty? x))

(module+ test
  (test-case "Basic JSON object check"
    (check-false (json-object? 5))
    (check-false (json-object? #t))
    (check-false (json-object? (list)))
    (check-true (json-object? (hasheq)))
    (check-true (json-object? (hasheq 'type "object")))))
