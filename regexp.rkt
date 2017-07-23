#lang racket/base

(module+ test
  (require rackunit))

(define (ecma-262-regexp? x)
  (string? x))

(provide ecma-262-regexp?)

(define (ecma-262-regexp-matches? regex str)
  #t)

(provide ecma-262-regexp-matches?)
