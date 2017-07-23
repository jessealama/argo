#lang racket/base

(require rackunit)
(require racket/path)

(require (only-in (file "../../parse.rkt")
                  parse-json-file))

(require (only-in (file "../../schema.rkt")
                  json-schema?))

(define positive-examples-directory (build-path "positive"))

(define negative-examples-directory (build-path "negative"))

(define (json-path? f)
  (let ([ext (path-get-extension f)])
    (and (bytes? ext)
         (bytes=? #".json" ext))))

(define (json-files-in-directory dir)
  (let ([things (directory-list dir #:build? #t)])
    (let ([files (filter file-exists? things)])
      (filter json-path? files))))

(define positive-examples
  (json-files-in-directory positive-examples-directory))

(define negative-examples
  (json-files-in-directory negative-examples-directory))

(module+ test
  (test-case "Positive examples"
    (for ([f positive-examples])
      (check-true (json-schema? (parse-json-file f))
                  (path->string f))))
  (test-case "Negative examples"
    (for ([f negative-examples])
      (check-false (json-schema? (parse-json-file f))
                   (path->string f)))))
