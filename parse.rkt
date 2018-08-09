#lang racket/base

(require ejs)
(require racket/port)
(require http/request)
(require (only-in net/url-string
                  url->string))
(require net/url-structs)
(require web-server/http/response-structs)
(require (only-in racket/list
                  empty))

(module+ test
  (require rackunit))

(define (parse-json-port p)
  (define (parse-fail err) (values #f #f))
  (with-handlers ([exn:fail? parse-fail])
    (let ([js (port->ejsexpr p)])
      (cond ((eof-object? js)
             (values #f #f))
            (else
             (values js #t))))))

(provide parse-json-port)

;; string? -> jsexpr? boolean?
(define (parse-json-string str)
  (define (parse-fail err) (values #f #f))
  (with-handlers ([exn:fail? parse-fail])
    (values (string->ejsexpr str) #t)))

(module+ test
  (let ([js "x"])
    (let-values ([(whatever ok?) (parse-json-string js)])
      (check-false ok?)))
  (let ([js "{}"])
    (let-values ([(whatever ok?) (parse-json-string js)])
      (check-true ok?))))

(provide parse-json-string)

;; bytes? -> jsexpr? boolean?
(define (parse-json-bytes bstr)
  (define (parse-fail err) (values #f #f))
  (with-handlers ([exn:fail? parse-fail])
    (values (bytes->ejsexpr bstr) #t)))

(provide parse-json-bytes)

(define (parse-json-file f)
  (let ([p (open-input-file f)])
    (begin0
        (parse-json-port p)
      (close-input-port p))))

(provide parse-json-file)

(define (parse-json-url u)
  (define url/str (url->string u))
  (define-values (path header)
    (uri&headers->path&header url/str (list)))
  (define-values (in out)
    (connect-uri url/str))
  (define ok? (start-request in
                             out
                             "1.1"
                             "GET"
                             path
                             header))
  (define h (purify-port/log-debug in))
  (define js/bytes (read-entity/bytes in h))
  (parse-json-bytes js/bytes))

(provide parse-json-url)

(define (parse-json-response r)
  (parse-json-bytes (call-with-output-bytes (response-output r))))

(module+ test
  (let ([r (response 301
                     #"OK"
                     (current-seconds)
                     #"text/html;charset=utf-8"
                     empty
                     (lambda (op) (write-bytes #"true" op)))])
    (let-values ([(js ok?) (parse-json-response r)])
      (check-true (ejsexpr? js))
      (check-true ok?)
      (check-true js))))

(define (can-parse? x)
  (or (and (path? x)
           (file-exists? x))
      (bytes? x)
      (string? x)
      (input-port? x)
      (url? x)
      (response? x)))

(define (parse-json js)
  (cond ((not (can-parse? js))
         (values #f #f))
        ((path? js)
         (parse-json-file js))
        ((bytes? js)
         (parse-json-bytes js))
        ((string? js)
         (parse-json-string js))
        ((input-port? js)
         (parse-json-port js))
        ((url? js)
         (parse-json-url js))
        (else
         (error "Cannot parse as JSON:" js))))

(provide parse-json)
