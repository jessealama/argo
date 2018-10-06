#lang racket/base

(provide ejsexpr?
         ejsexpr/c
         ejs-number?
         ejs-integer?
         ejs-object?
         ejs-array?
         ejs-boolean?
         ejs-true?
         ejs-false?
         ejs-string?
         ejs-null?)

(require racket/contract)

(module+ test
  (require rackunit))

(define (ejsexpr? x)
  (or (ejs-null? x)
      (ejs-number? x)
      (ejs-boolean? x)
      (ejs-string? x)
      (ejs-array? x)
      (ejs-object? x)))

(module+ test
  (check-true (ejsexpr? 'null))
  (check-false (ejsexpr? 'nul))
  (check-true (ejsexpr? 0))
  (check-true (ejsexpr? 100000000000000000000000000000000))
  (check-true (ejsexpr? -100))
  (check-false (ejsexpr? +inf.0))
  (check-false (ejsexpr? -inf.0))
  (check-true (ejsexpr? 4/5))
  (check-false (ejsexpr? 1+1i))
  (check-true (ejsexpr? #t))
  (check-true (ejsexpr? #f))
  (check-true (ejsexpr? (list)))
  (check-false (ejsexpr? (list 'nul)))
  (check-false (ejsexpr? (hash 'a "b")))
  (check-false (ejsexpr? (hasheq 'a 'a)))
  (check-true (ejsexpr? (hasheq 'a "b")))
  (check-false (ejsexpr? (hasheq "a" "a"))))

(define ejsexpr/c
  (make-flat-contract #:name 'ejsexpr/c
                      #:first-order ejsexpr?))

(define/contract (ejs-number? x)
  (any/c . -> . boolean?)
  (and (number? x)
       (real? x)
       (exact? x)))

(module+ test
  (check-true (ejs-number? 0))
  (check-false (ejs-number? #t))
  (check-false (ejs-number? 0.24))
  (check-true (ejs-number? #e0.24))
  (check-true (ejs-number? -1))
  (check-true (ejs-number? #e-4.56))
  (check-false (ejs-number? -4.56)))

(define/contract (ejs-integer? x)
  (any/c . -> . boolean?)
  (and (ejs-number? x)
       (integer? x)))

(module+ test
  (check-true (ejs-integer? 0))
  (check-false (ejs-integer? #t))
  (check-false (ejs-integer? 0.24))
  (check-false (ejs-integer? #e0.24))
  (check-true (ejs-integer? -1))
  (check-true (ejs-integer? #e1234567890123456789))
  (check-true (ejs-integer? #e-1234567890123456789))
  (check-false (ejs-integer? #e-4.56))
  (check-false (ejs-number? -4.56)))

(define/contract (ejs-object? x)
  (any/c . -> . boolean?)
  (and (hash? x)
       (hash-eq? x)
       (andmap symbol? (hash-keys x))
       (andmap ejsexpr? (hash-values x))))

(define/contract (ejs-array? x)
  (any/c . -> . boolean?)
  (and (list? x)
       (andmap ejsexpr? x)))

(define/contract (ejs-boolean? x)
  (any/c . -> . boolean?)
  (boolean? x))

(define/contract (ejs-true? x)
  (any/c . -> . boolean?)
  (eq? x #t))

(define/contract (ejs-false? x)
  (any/c . -> . boolean?)
  (eq? x #f))

(define/contract (ejs-string? x)
  (any/c . -> . boolean?)
  (string? x))

(define/contract (ejs-null? x)
  (any/c . -> . boolean?)
  (and (symbol? x)
       (eq? x 'null)))
