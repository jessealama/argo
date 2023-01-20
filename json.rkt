#lang racket/base

(provide has-type?
         has-property?
         property-value
         object-properties
         object-values
         json-non-negative-integer?
         remove-property
         count-properties)

(require (file "util.rkt")
         racket/cmdline
         racket/match
         racket/contract
         racket/list
         json)

(module+ test
  (require rackunit))

;; constructors

(define/contract (has-property? obj prop)
  (hash? (or/c symbol? string?) . -> . boolean?)
  (cond ((symbol? prop)
         (hash-has-key? obj prop))
        ((string? prop)
         (hash-has-key? obj (string->symbol prop)))))

(module+ test
  (let ([obj (hasheq 'foo "bar")])
    (check-true (hash? obj))
    (check-true (has-property? obj 'foo))
    (check-true (has-property? obj "foo"))
    (check-false (has-property? obj 'bar))
    (check-false (has-property? obj "bar"))))

(define/contract (property-value obj prop)
  (hash? (or/c string? symbol?) . -> . jsexpr?)
  (cond [(symbol? prop)
         (hash-ref obj prop)]
        [(string? prop)
         (hash-ref obj (string->symbol prop))]))

(define/contract (object-properties obj)
  (hash? . -> . (listof symbol?))
  (hash-keys obj))

(define/contract (object-values obj)
  (hash? . -> . (listof jsexpr?))
  (hash-values obj))

(define/contract (json-non-negative-integer? x)
  (jsexpr? . -> . boolean?)
  (and (integer? x)
       (<= 0 x)))

(define/contract (remove-property jsobj prop)
  (hash? symbol? . -> . hash?)
  (hash-remove jsobj prop))

(define/contract (count-properties js)
  (hash? . -> . exact-nonnegative-integer?)
  (length (object-properties js)))

(define/contract (has-type? data type)
  (jsexpr? (or/c string? (listof string?)) . -> . boolean?)
  (match type
    [(? list?)
     (ormap (lambda (t) (has-type? data t))
            type)]
    ["null"
     (eq? 'null data)]
    ["boolean"
     (boolean? data)]
    ["number"
     (number? data)]
    ["integer"
     (integer? data)]
    ["object"
     (hash? data)]
    ["array"
     (list? data)]
    ["string"
     (string? data)]
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

  (with-handlers ([exn:fail:read? (lambda (e)
                                    (exit 1))])
    (string->jsexpr json/string)
    (exit 0)))
