#lang racket/base

(require (only-in ejs
                  ejsexpr?
                  equal-ejsexprs?
                  ejs-null?
                  ejs-boolean?
                  ejs-number?
                  ejs-integer?
                  ejs-string?
                  ejs-array?
                  ejs-object?))

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

(require racket/contract)

(module+ test
  (require rackunit))

;; constructors

(define (json-string x)
  (unless (string? x)
    (error "To make a JSON string, a Racket string is required."))
  x)

(provide json-string)

(define (json-number x)
  (unless (real? x)
    (error "To make a JSON number, a Racket real? value is required." x))
  x)

(provide json-number)

(define/contract (json-array . items)
  ((listof ejsexpr?) . -> . ejs-array?)
  (apply list items))

(provide json-array)

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

(define (array-items arr)
  arr)

(provide array-items)

(define (array-ref arr idx)
  (list-ref (array-items arr) idx))

(provide array-ref)

(define (array-length arr)
  (length (array-items arr)))

(provide array-length)

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
    (check-true (ejs-object? obj))
    (check-true (has-property? obj 'foo))
    (check-true (has-property? obj "foo"))
    (check-false (has-property? obj 'bar))
    (check-false (has-property? obj "bar"))))

(provide has-property?)

(define (property-value obj prop)
  (cond ((symbol? prop)
         (hash-ref obj prop))
        ((string? prop)
         (hash-ref obj (string->symbol prop)))
        (else
         (error "Property should be either a symbol or a string." prop))))

(provide property-value)

;; assumes x is a json-array? value
(define (empty-array? x)
  (empty? x))

(provide empty-array?)

(define (object-properties obj)
  (hash-keys obj))

(provide object-properties)

(define (object-values obj)
  (hash-values obj))

(provide object-values)

(define (json-non-negative-integer? x)
  (and (ejs-integer? x)
       (<= 0 x)))

(provide json-non-negative-integer?)

(define (remove-property jsobj prop)
  (hash-remove jsobj prop))

(provide remove-property)

(define (count-properties js)
  (length (object-properties js)))

(provide count-properties)

(define (has-type? data type)
  (unless (string? type)
    (error "Type should be a string: " type))
  (cond ((string=? type "null")
         (ejs-null? data))
        ((string=? type "boolean")
         (ejs-boolean? data))
        ((string=? type "number")
         (ejs-number? data))
        ((string=? type "integer")
         (ejs-integer? data))
        ((string=? type "object")
         (ejs-object? data))
        ((string=? type "array")
         (ejs-array? data))
        ((string=? type "string")
         (ejs-string? data))
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
