#lang racket/base

(require json)
(require racket/port)
(require (only-in (file "util.rkt")
                  bytes->string))
(require http/request)
(require (only-in net/url-string
                  url->string))
(require net/url-structs)

(module+ test
  (require rackunit))

(define (parse-json-port p)
  (define (parse-fail err) (values #f #f))
  (with-handlers ([exn:fail:read? parse-fail])
    (let ([js (read-json p)])
      (cond ((eof-object? js)
             (values #f #f))
            (else
             (values js #t))))))

(provide parse-json-port)

(define (parse-json-string str)
  (let ([p (open-input-string str)])
    (begin0
        (parse-json-port p)
      (close-input-port p))))

(module+ test
  (let ([js "x"])
    (let-values ([(whatever ok?) (parse-json-string js)])
      (check-false ok?)))
  (let ([js "{}"])
    (let-values ([(whatever ok?) (parse-json-string js)])
      (check-true ok?))))

(provide parse-json-string)

(define (parse-json-bytes bstr)
  (let ([str (bytes->string bstr)])
    (if (string? str)
        (parse-json-string str)
        (values #f #f))))

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

(define (can-parse? x)
  (cond ((path? x)
         (file-exists? x))
        ((bytes? x)
         #t)
        ((string? x)
         #t)
        ((input-port? x)
         #t)
        ((url? x)
         #t)
        (else
         #f)))

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
