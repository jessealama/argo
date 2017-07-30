#lang racket/base

(require (only-in json
                  jsexpr?))

(require (only-in racket/list
                  empty?
                  first
                  rest))

(require (only-in racket/cmdline
                  command-line))

(require (only-in (file "util.rkt")
                  complain-and-die
                  file-content/bytes
                  bytes->string))

(require (only-in (file "parse.rkt")
                  parse-json-string))

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

;; constructors

(define (json-string x)
  (unless (string? x)
    (error "To make a JSON string, a Racket string is required."))
  x)

(provide json-string)

;; assumes that x is already a jsexpr? value
(define (json-null? x)
  (eq? x 'null))

(provide json-null?)

(module+ test
  (test-case "JSON null"
    (check-true (json-null? 'null))
    (check-false (json-null? (list)))
    (check-false (json-null? (hasheq)))
    (check-false (json-null? "null"))
    (check-false (json-null? 0))
    (check-false (json-null? #f))))

;; assumes that x is already a jsexpr? value
(define (json-boolean? x)
  (boolean? x))

(provide json-boolean?)

(define (json-true-value? x)
  (eq? x #t))

(provide json-true-value?)

(define (json-false-value? x)
  (eq? x #f))

(provide json-false-value?)

;; assumes that x is already a jsexpr? value
(define (json-array? x)
  (list? x))

(provide json-array?)

(module+ test
  (check-true (json-array? (list)))
  (check-false (json-array? (hasheq))))

(define (array-items arr)
  arr)

(provide array-items)

(define (array-length arr)
  (length (array-items arr)))

(provide array-length)

;; assumes that x is already a jsexpr? value
(define (json-number? x)
  (real? x))

(module+ test
  (check-true (json-number? 4))
  (check-false (json-number? #t))
  (check-false (json-number? (hasheq)))
  (check-true (json-number? -4.5))
  (check-true (json-number? 3.141592653589793238462643383279)))

(provide json-number?)

(define (json-integer? x)
  (integer? x))

(module+ test
  (test-case "JSON integers"
     (check-true (json-integer? 4))
     (check-true (json-integer? -4))
     (check-true (json-integer? 4.0))
     (check-false (json-integer? 4.1))
     (check-false (json-integer? #t))))

(define (has-property? obj prop)
  (cond ((symbol? prop)
         (hash-has-key? obj prop))
        ((string? prop)
         (hash-has-key? obj (string->symbol prop)))
        (else
         #f)))

(module+ test
  (let ([obj (hasheq
              'foo "bar")])
    (check-true (jsexpr? obj))
    (check-true (has-property? obj 'foo))
    (check-true (has-property? obj "foo"))
    (check-false (has-property? obj 'bar))
    (check-false (has-property? obj "bar"))))

(provide has-property?)

(define (property-value obj prop)
  (hash-ref obj prop))

(provide property-value)

;; assumes x is a json-array? value
(define (empty-array? x)
  (empty? x))

(provide empty-array?)

(module+ test
  (test-case "Basic JSON object check"
    (check-false (json-object? 5))
    (check-false (json-object? #t))
    (check-false (json-object? (list)))
    (check-true (json-object? (hasheq)))
    (check-true (json-object? (hasheq 'type "object")))))

(define (object-properties obj)
  (hash-keys obj))

(provide object-properties)

(define (object-values obj)
  (hash-values obj))

(provide object-values)

(define (json-non-negative-integer? x)
  (and (json-integer? x)
       (<= 0 x)))

(provide json-non-negative-integer?)

(define (json-equal-arrays? jsarr1 jsarr2)
  (if (empty? jsarr1)
      (empty? jsarr2)
      (if (empty? jsarr2)
          #f
          (let ([a1 (first jsarr1)]
                [b1 (first jsarr2)]
                [as (rest jsarr1)]
                [bs (rest jsarr2)])
            (and (json-equal? a1 b1)
                 (json-equal-arrays? as bs))))))

(define (remove-property jsobj prop)
  (hash-remove jsobj prop))

(provide remove-property)

(define (json-equal-objects? jsobj1 jsobj2)
  (let ([props1 (object-properties jsobj1)])
    (if (empty? props1)
        (empty? (object-properties jsobj2))
        (let ([prop1 (first props1)])
          (and (has-property? jsobj2 prop1)
               (let ([val1 (property-value jsobj1 prop1)]
                     [val2 (property-value jsobj2 prop1)])
                 (and (json-equal? val1 val2)
                      (json-equal? (remove-property jsobj1 prop1)
                                   (remove-property jsobj2 prop1)))))))))

;; assumes that both arguments as jsexpr? values
(define (json-equal? js1 js2)
  (cond ((json-null? js1)
         (json-null? js2))
        ((json-string? js1)
         (and (json-string? js2)
              (string=? js1 js2)))
        ((json-number? js1)
         (and (json-number? js2)
              (= js1 js2)))
        ((json-boolean? js1)
         (and (json-boolean? js2)
              (eq? js1 js2)))
        ((json-array? js1)
         (and (json-array? js2)
              (json-equal-arrays? js1 js2)))
        ((json-object? js1)
         (and (json-object? js2)
              (json-equal-objects? js1 js2)))
        (else
         (error "Unknown type: Don't know how to deal with ~a." js1))))

(provide json-equal?)

(module+ test

  (test-case "Null equality"
    (check-true (json-equal? 'null 'null))
    (check-false (json-equal? 'null "null")))
  (test-case "String equality"
    (check-true (json-equal? "dog" "dog"))
    (check-false (json-equal? "a" "A"))
    (check-true (json-equal? "" ""))
    (check-true (json-equal? "düg" "d\u00fcg"))
    (check-false (json-equal? "null" 'null)))

  (test-case "Boolean equality"
    (check-true (json-equal? #f #f))
    (check-true (json-equal? #t #t))
    (check-false (json-equal? #f #t))
    (check-false (json-equal? #t 1))
    (check-false (json-equal? #f 0)))

  (test-case "Number equality"
    (check-true (json-equal? 0 0))
    (check-true (json-equal? 0 0.0))
    (check-false (json-equal? -1 -0.999999999))
    (check-true (json-equal? 3.141592654 3.141592654))
    (check-false (json-equal? 3.141592654 3.141592653))
    (check-true (json-equal? 4 4.000000000000))
    (check-false (json-equal? 4 4.000000000001)))

  (test-case "Object equality"
    (check-true (json-equal? (hasheq)
                             (hasheq)))
    (check-true (json-equal? (hasheq 'foo "bar")
                             (hasheq 'foo "bar")))
    (check-true (json-equal? (hasheq 'foo 'null)
                             (hasheq 'foo 'null)))
    (check-true (json-equal? (hasheq 'a "b"
                                     'c "d")
                             (hasheq 'c "d"
                                     'a "b")))
    (check-false (json-equal? (hasheq 'a "b"
                                      'c "d")
                              (hasheq 'a "d"
                                      'c "d")))
    (check-true (json-equal? (hasheq 'a "düg")
                             (hasheq 'a "d\u00fcg")))
    (check-true (json-equal? (hasheq 'a "b"
                                     'c (hasheq 'a "b"))
                             (hasheq 'a "b"
                                     'c (hasheq 'a "b"))))
    (check-true (json-equal? (hasheq 'a "b"
                                     'c (list "a" "b"))
                             (hasheq 'c (list "a" "b")
                                     'a "b"))))

  (test-case "Array equality"
    (check-true (json-equal? (list) (list)))
    (check-false (json-equal? (list "a") (list)))
    (check-false (json-equal? (list) (hasheq)))
    (check-true (json-equal? (list "a" (hasheq 'a "b"))
                             (list "a" (hasheq 'a "b"))))
    (check-false (json-equal? (list "a" "b")
                              (list "b" "a")))
    (check-true (json-equal? (list (list "a" "b"))
                             (list (list "a" "b"))))))

(define (count-properties js)
  (length (object-properties js)))

(provide count-properties)

(define (has-type? data type)
  (unless (string? type)
    (error "Type should be a string: " type))
  (cond ((string=? type "null")
         (json-null? data))
        ((string=? type "boolean")
         (json-boolean? data))
        ((string=? type "number")
         (json-number? data))
        ((string=? type "integer")
         (json-integer? data))
        ((string=? type "object")
         (json-object? data))
        ((string=? type "array")
         (json-array? data))
        ((string=? type "string")
         (json-string? data))
        (else
         (error "Unknown JSON data type: " type))))

(provide has-type?)

;; Command line application for testing whether a file is
;; a JSON file at all

(module+ main
  (define json-path
    (command-line
     #:program "json"
     #:args (json-path)
     json-path))
  (unless (file-exists? json-path)
    (complain-and-die (format "Schema file \"~a\" does not exist." json-path)))
  (define (parse-fail err) #f)
  (define json/bytes (file-content/bytes json-path))
  (define json/string (bytes->string json/bytes))
  (when (eq? json/string #f)
    (complain-and-die (format "Contents of \"~a\" cannot be interpreted as a UTF-8 string." json-path)))
  (define-values (json/jsexpr json-well-formed?)
    (parse-json-string json/string))
  (exit (if json-well-formed?
            0
            1)))
