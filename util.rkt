#lang racket/base

(require (only-in racket/list
                  remove-duplicates)
         (only-in racket/path
                  path-get-extension))

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
