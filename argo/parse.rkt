#lang racket/base

(require json)
(require racket/port)

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
  (parse-json-string (bytes->string/utf-8 bstr)))

(provide parse-json-bytes)

(define (parse-json-file f)
  (let ([p (open-input-file f)])
    (begin0
        (parse-json-port p)
      (close-input-port p))))

(provide parse-json-file)
