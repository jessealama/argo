#lang racket/base

(provide has-type?
         has-property?
         property-value
         object-properties
         object-values
         json-non-negative-integer?
         remove-property
         count-properties)

(require (only-in (file "parse.rkt")
                  parse-json-string)
         (only-in (file "util.rkt")
                  complain-and-die
                  file-content/bytes
                  bytes->string)
         (only-in ejs
                  ejs-null?
                  ejs-boolean?
                  ejs-number?
                  ejs-integer?
                  ejs-string?
                  ejs-array?
                  ejs-object?)
         (only-in racket/cmdline
                  command-line)
         racket/contract
         (only-in racket/list
                  empty?
                  first
                  rest))

(module+ test
  (require rackunit))

;; constructors

(define/contract (has-property? obj prop)
  (ejs-object? (or/c symbol? string?) . -> . boolean?)
  (cond ((symbol? prop)
         (hash-has-key? obj prop))
        ((string? prop)
         (hash-has-key? obj (string->symbol prop)))))

(module+ test
  (let-test ([obj (hasheq 'foo "bar")])
    (check-true (ejs-object? obj))
    (check-true (has-property? obj 'foo))
    (check-true (has-property? obj "foo"))
    (check-false (has-property? obj 'bar))
    (check-false (has-property? obj "bar"))))

(define/contract (property-value obj prop)
  (ejs-object? (or/c string? symbol?) . -> . boolean?)
  (cond [(symbol? prop)
         (hash-ref obj prop)]
        [(string? prop)
         (hash-ref obj (string->symbol prop))]))

(define (object-properties obj)
  (hash-keys obj))

(define (object-values obj)
  (hash-values obj))

(define (json-non-negative-integer? x)
  (and (ejs-integer? x)
       (<= 0 x)))

(define (remove-property jsobj prop)
  (hash-remove jsobj prop))

(define (count-properties js)
  (length (object-properties js)))

(define/contract (has-type? data type)
  (ejsexpr? string? . -> . boolean?)
  (match type
    ["null"
     (ejs-null? data)]
    ["boolean"
     (ejs-boolean? data)]
    ["number"
     (ejs-number? data)]
    ["integer"
     (ejs-integer? data)]
    ["object"
     (ejs-object? data)]
    ["array"
     (ejs-array? data)]
    ["string"
     (ejs-string? data)]
    [else
     (error "Unknown JSON data type: " type)]))



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
