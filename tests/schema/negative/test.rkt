#lang racket/base

(require rackunit)

(require (only-in (file "../../../util.rkt")
                  json-files-in-directory))

(require (only-in (file "../../../parse.rkt")
                  parse-json-file))

(require (only-in (file "../../../schema.rkt")
                  json-schema?))

(require (only-in racket/cmdline
                  command-line))

(require (only-in racket/list
                  empty?))

(define (check-directory dir)
  (define examples (json-files-in-directory dir))
  (cond ((empty? examples)
         #f)
        (else
         (for ([f examples])
           (check-false (json-schema? (parse-json-file f))
                        (path->string f))))))

(module+ main
  (define directory-to-check
    (command-line
     #:args (dir)
     dir))
  (let ([result (check-directory directory-to-check)])
    (cond ((eq? result #f)
           (display (format "No JSON files in ~a." directory-to-check))
           (newline)
           (exit 1))
          (else
           (exit 0)))))
