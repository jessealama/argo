#lang racket/base

(module+ test
  (require rackunit))

(define (ecma-262-regexp? x)
  (string? x))

(provide ecma-262-regexp?)

;; Incomplete: this uses Racket regular expressions, not ECMA 262
;; regular expressions!
;;
;; Consider looking at: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Regular_Expressions
(define (ecma-262-regexp-matches? regex str)
  (regexp-match? (regexp regex) str))

(provide ecma-262-regexp-matches?)

(module+ test
  (check-true (ecma-262-regexp-matches? "abc" "abc"))
  (check-false (ecma-262-regexp-matches? "a" "b"))
  (check-true (ecma-262-regexp-matches? "a" "ba"))
  (check-true (ecma-262-regexp-matches? "a.*" "a"))
  (check-true (ecma-262-regexp-matches? ".*a" "a"))
  (check-true (ecma-262-regexp-matches? "^ag" "ag"))
  (check-false (ecma-262-regexp-matches? "^ab" "a"))
  (check-true (ecma-262-regexp-matches? "^r$" "r"))
  (check-false (ecma-262-regexp-matches? "a" "A"))

  ;; Examples from https://spacetelescope.github.io/understanding-json-schema/reference/regular_expressions.html
  (let ([r "^(\\([0-9]{3}\\))?[0-9]{3}-[0-9]{4}$"])
    (check-true (ecma-262-regexp-matches? r "555-1212"))
    (check-true (ecma-262-regexp-matches? r "(888)555-1212"))
    (check-false (ecma-262-regexp-matches? r "(888)555-1212 ext. 532"))
    (check-false (ecma-262-regexp-matches? r "(800)FLOWERS"))))
