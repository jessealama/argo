#lang racket/base

(provide evaluate
         evaluate/1)

(require (only-in racket/match
                  match)
         racket/contract
         (only-in racket/list
                  first
                  drop-right)
         (only-in racket/hash
                  hash-union)
         (file "value.rkt"))

(define/contract (eval-object-item item)
  (list? . -> . ejs-object?)
  (match item
    [(list 'object-item (? string? prop) ":" val)
     (hasheq (string->symbol prop)
             (evaluate/1 val))]
    [else
     (error (format "Cannot evaluate object item ~a" item))]))

(define/contract (evaluate/1 ejsexpr)
  (list? . -> . ejsexpr?)
  (match ejsexpr
    [(list 'ejsexprs)
     (error "Cannot evaluate the empty list!")]
    [(list 'ejsexprs e)
     (first (evaluate ejsexpr))]
    [(list-rest 'ejsexprs e more)
     (evaluate/1 (list 'ejsexprs e))]
    [(list 'ejsexpr more)
     (match more
       [(list 'string (? string? s))
        s]
       [(list 'null "null")
        'null]
       [(list 'boolean b)
        (match b
          ["true"
           #t]
          ["false"
           #f]
          [else
           (error (format "evaluate/1: Don't know how to evaluate boolean ~a" b))])]
       [(list 'number (? string? n))
        (string->number n
                        10
                        'number-or-false
                        'decimal-as-exact)]
       [(list-rest 'array "[" items)
        (map evaluate/1 (remove* (list ",")
                                 (drop-right items 1)))]
       [(list 'object "{" "}")
        (hasheq)]
       [(list-rest 'object "{" items)
        (apply hash-union
               (map eval-object-item
                    (remove* (list ",")
                             (drop-right items 1))))]
       [else
        (error (format "evaluate/1: Don't know how to evaluate ~a" more))])]
    [else
     (error (format "evaluate/1: Don't know how to evaluate ~a" ejsexpr))]))

(define/contract (evaluate ejsexpr)
  (list? . -> . (listof ejsexpr?))
  (match ejsexpr
    [(list 'ejsexprs exprs ...)
     (map evaluate/1 exprs)]
    [else
     (error (format "evaluate: Don't know how to evaluate ~a" ejsexpr))]))
