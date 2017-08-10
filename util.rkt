#lang racket/base

(require (only-in racket/list
                  remove-duplicates
                  empty?)
         (only-in racket/path
                  path-get-extension)
         (only-in racket/port
                  port->bytes)
         net/url-structs)

(module+ test
  (require rackunit))

(define (intersection l1 l2)
  (let ([l2-no-duplicates (remove-duplicates l2)])
    (filter (lambda (x)
              (member x l2-no-duplicates))
            (remove-duplicates l1))))

(provide intersection)

(module+ test
  (check-equal? (intersection (list 1 2) (list 1))
               (list 1))
  (check-equal? (intersection (list) (list 1))
               (list))
  (check-equal? (intersection (list 1) (list))
               (list))
  (check-equal? (intersection (list 1 2) (list 2 1))
               (list 1 2))
  (check-equal? (intersection (list 1 2 1) (list 2))
               (list 2)))

(define (json-path? f)
  (let ([ext (path-get-extension f)])
    (and (bytes? ext)
         (bytes=? #".json" ext))))

(provide json-path?)

(define (json-files-in-directory dir)
  (let ([things (directory-list dir #:build? #t)])
    (let ([files (filter file-exists? things)])
      (filter json-path? files))))

(provide json-files-in-directory)

(define (file-content/bytes path)
  (let ([p (open-input-file path)])
    (begin0
        (port->bytes p)
      (close-input-port p))))

(provide file-content/bytes)

(define (bytes->string bstr)
  (define (fail err) #f)
  (with-handlers ([exn:fail:contract? fail])
    (bytes->string/utf-8 bstr)))

(provide bytes->string)

(define (complain-and-die message)
  (display message)
  (newline)
  (exit 1))

(provide complain-and-die)

(define (url-has-only-fragment? u)
  (and (eq? #f (url-scheme u))
       (eq? #f (url-user u))
       (eq? #f (url-host u))
       (eq? #f (url-port u))
       (not (url-path-absolute? u))
       (empty? (url-path u))
       (empty? (url-query u))
       (string? (url-fragment u))))

(provide url-has-only-fragment?)
