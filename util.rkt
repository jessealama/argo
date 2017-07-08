#lang racket/base

(require (only-in racket/list
                  remove-duplicates))

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
