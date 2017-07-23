#lang racket/base

(require json)
(require racket/port)

(module+ test
  (require rackunit))

(define (parse-json-port p)
  (let ([js (read-json p)])
    (when (eof-object? js)
      (error "End-of-file reached while parsing JSON."))
    js))

(provide parse-json-port)

(module+ test
  (let* ([js "x"]
         [p (open-input-string js)])
    (check-exn exn:fail:read? (lambda () (parse-json-port p)))
    (close-input-port p))
  (let* ([js "{}"]
         [p (open-input-string js)])
    (check-true (jsexpr? (parse-json-port p)))
    (close-input-port p)))

(define (parse-json-file f)
  (let ([p (open-input-file f)])
    (begin0
        (parse-json-port p)
      (close-input-port p))))

(provide parse-json-file)
