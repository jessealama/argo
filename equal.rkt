#lang racket/base

(provide equal-jsexprs?)

(require (only-in racket/list
                  empty?
                  first
                  rest)
         racket/contract
         json)

(module+ test
  (require rackunit))

(define/contract (has-property? obj prop)
  (hash? (or/c symbol? string?) . -> . boolean?)
  (cond [(symbol? prop)
         (hash-has-key? obj prop)]
        [(string? prop)
         (hash-has-key? obj (string->symbol prop))]))

(module+ test
  (let ([obj (hasheq
              'foo "bar")])
    (check-true (jsexpr? obj))
    (check-true (has-property? obj 'foo))
    (check-true (has-property? obj "foo"))
    (check-false (has-property? obj 'bar))
    (check-false (has-property? obj "bar"))))

(define (property-value obj prop)
  (cond ((symbol? prop)
         (hash-ref obj prop))
        ((string? prop)
         (hash-ref obj (string->symbol prop)))
        (else
         (error "Property should be either a symbol or a string." prop))))

(define (object-properties obj)
  (hash-keys obj))

(define (object-values obj)
  (hash-values obj))

(define (equal-arrays? jsarr1 jsarr2)
  (if (empty? jsarr1)
      (empty? jsarr2)
      (if (empty? jsarr2)
          #f
          (let ([a1 (first jsarr1)]
                [b1 (first jsarr2)]
                [as (rest jsarr1)]
                [bs (rest jsarr2)])
            (and (equal-jsexprs? a1 b1)
                 (equal-arrays? as bs))))))

(define (remove-property jsobj prop)
  (hash-remove jsobj prop))

(define (equal-objects? jsobj1 jsobj2)
  (let ([props1 (object-properties jsobj1)])
    (if (empty? props1)
        (empty? (object-properties jsobj2))
        (let ([prop1 (first props1)])
          (and (has-property? jsobj2 prop1)
               (let ([val1 (property-value jsobj1 prop1)]
                     [val2 (property-value jsobj2 prop1)])
                 (and (equal-jsexprs? val1 val2)
                      (equal-jsexprs? (remove-property jsobj1 prop1)
                                      (remove-property jsobj2 prop1)))))))))

(define/contract (equal-jsexprs? js1 js2)
  (jsexpr? jsexpr? . -> . boolean?)
  (cond [(eq? 'null js1)
         (eq? 'null js2)]
        [(string? js1)
         (and (string? js2)
              (string=? js1 js2))]
        [(number? js1)
         (and (number? js2)
              (= js1 js2))]
        [(boolean? js1)
         (and (boolean? js2)
              (eq? js1 js2))]
        [(list? js1)
         (and (list? js2)
              (equal-arrays? js1 js2))]
        [(hash? js1)
         (and (hash? js2)
              (equal-objects? js1 js2))]))

(module+ test

  (test-case "Null equality"
    (check-true (equal-jsexprs? 'null 'null))
    (check-false (equal-jsexprs? 'null "null")))
  (test-case "String equality"
    (check-true (equal-jsexprs? "dog" "dog"))
    (check-false (equal-jsexprs? "a" "A"))
    (check-true (equal-jsexprs? "" ""))
    (check-true (equal-jsexprs? "düg" "d\u00fcg"))
    (check-false (equal-jsexprs? "null" 'null)))

  (test-case "Boolean equality"
    (check-true (equal-jsexprs? #f #f))
    (check-true (equal-jsexprs? #t #t))
    (check-false (equal-jsexprs? #f #t))
    (check-false (equal-jsexprs? #t 1))
    (check-false (equal-jsexprs? #f 0)))

  (test-case "Number equality"
    (check-true (equal-jsexprs? #e0 #e0))
    (check-true (equal-jsexprs? #e0 #e0.0))
    (check-false (equal-jsexprs? -1 0.999999999))
    (check-true (equal-jsexprs? 3.141592654 3.141592654))
    (check-false (equal-jsexprs? 3.141592654 3.141592653))
    (check-true (equal-jsexprs? 4 4.000000000000))
    (check-false (equal-jsexprs? 4 4.000000000001)))

  (test-case "Object equality"
    (check-true (equal-jsexprs? (hasheq)
                             (hasheq)))
    (check-true (equal-jsexprs? (hasheq 'foo "bar")
                             (hasheq 'foo "bar")))
    (check-true (equal-jsexprs? (hasheq 'foo 'null)
                             (hasheq 'foo 'null)))
    (check-true (equal-jsexprs? (hasheq 'a "b"
                                     'c "d")
                             (hasheq 'c "d"
                                     'a "b")))
    (check-false (equal-jsexprs? (hasheq 'a "b"
                                      'c "d")
                              (hasheq 'a "d"
                                      'c "d")))
    (check-true (equal-jsexprs? (hasheq 'a "düg")
                             (hasheq 'a "d\u00fcg")))
    (check-true (equal-jsexprs? (hasheq 'a "b"
                                     'c (hasheq 'a "b"))
                             (hasheq 'a "b"
                                     'c (hasheq 'a "b"))))
    (check-true (equal-jsexprs? (hasheq 'a "b"
                                     'c (list "a" "b"))
                             (hasheq 'c (list "a" "b")
                                     'a "b"))))

  (test-case "Array equality"
    (check-true (equal-jsexprs? (list) (list)))
    (check-false (equal-jsexprs? (list "a") (list)))
    (check-false (equal-jsexprs? (list) (hasheq)))
    (check-true (equal-jsexprs? (list "a" (hasheq 'a "b"))
                             (list "a" (hasheq 'a "b"))))
    (check-false (equal-jsexprs? (list "a" "b")
                              (list "b" "a")))
    (check-true (equal-jsexprs? (list (list "a" "b"))
                             (list (list "a" "b"))))))
