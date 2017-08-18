#lang racket/base

(require (only-in racket/list
                  remove-duplicates
                  empty?
                  first
                  rest)
         (only-in racket/path
                  path-get-extension)
         (only-in racket/port
                  port->bytes)
         net/url-structs
         net/url-string)

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

(module+ test
  (let ([empty-url (url #f #f #f #f #f (list) (list) #f)])
    (check-false (url-has-only-fragment? empty-url))
    (check-true (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [scheme "gopher"])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [user "joe"])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [host "stargazer.io"])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [port 98123])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [path-absolute? #t])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [path (list (path/param 'up (list)))])))
    (check-false (url-has-only-fragment? (struct-copy url
                                                     empty-url
                                                     [fragment "Bob"]
                                                     [query (list (cons 'download #f))]))))
  (check-true (url-has-only-fragment? (string->url "#foobazi")))
  (check-false (url-has-only-fragment? (string->url "http://docs.racket-lang.org:994/"))))

(define (url-schemes-equal? url-1 url-2)
  (let ([s-1 (url-scheme url-1)]
        [s-2 (url-scheme url-2)])
    (or (and (eq? #f s-1)
             (eq? #f s-2))
        (string=? s-1 s-2))))

(define (url-users-equal? url-1 url-2)
  (let ([u-1 (url-user url-1)]
        [u-2 (url-user url-2)])
    (or (and (eq? #f u-1)
             (eq? #f u-2))
        (string=? u-1 u-2))))

(define (url-hosts-equal? url-1 url-2)
  (let ([h-1 (url-host url-1)]
        [h-2 (url-host url-2)])
    (or (and (eq? #f h-1)
             (eq? #f h-2))
        (string=? h-1 h-2))))

(define (url-ports-equal? url-1 url-2)
  (let ([p-1 (url-port url-1)]
        [p-2 (url-port url-2)])
    (or (and (eq? #f p-1)
             (eq? #f p-2))
        (= p-1 p-2))))

(define (url-paths-absolute? url-1 url-2)
  (let ([a-1? (url-path-absolute? url-1)]
        [a-2? (url-path-absolute? url-2)])
    (eq? a-1? a-2?)))

(define (path/param-paths-equal? path/param-1 path/param-2)
  (let ([path-1 (path/param-path path/param-1)]
        [path-2 (path/param-path path/param-1)])
    (or (and (eq? path-1 'up)
             (eq? path-2 'up))
        (and (eq? path-1 'same)
             (eq? path-2 'same))
        (string=? path-1 path-2))))

(define (string-lists-equal? l-1 l-2)
  (cond ((null? l-1)
         (null? l-2))
        ((null? l-2)
         #f)
        ((string=? (first l-1) (first l-2))
         (string-lists-equal? (rest l-1) (rest l-2)))
        (else
         #f)))

(define (path/param-params-equal? path/param-1 path/param-2)
  (let ([param-1 (path/param-param path/param-1)]
        [param-2 (path/param-param path/param-1)])
    (string-lists-equal? param-1 param-2)))

(define (path/params-equal? path/param-1 path/param-2)
  (and (path/param-paths-equal? path/param-1 path/param-2)
       (path/param-params-equal? path/param-1 path/param-2)))

(define (url-paths-equal? url-1 url-2)
  (define (equal? l-1 l-2)
    (cond ((null? l-1)
           (null? l-2))
          ((null? l-2)
           #f)
          ((path/params-equal? (first l-1) (first l-2))
           (equal? (rest l-1) (rest l-2)))
          (else
           #f)))
  (let ([p-1 (url-path url-1)]
        [p-2 (url-path url-2)])
    (equal? p-1 p-2)))

(define (query-lists-equal? l-1 l-2)
    (cond ((null? l-1)
           (null? l-2))
          ((null? l-2)
           #f)
          ((eq? (car (first l-1)) (car (first l-2)))
           (and (or (and (eq? #f (cdr (first l-1)))
                         (eq? #f (cdr (first l-2))))
                    (string=? (cdr (first l-1)) (cdr (first l-2))))
                (query-lists-equal? (rest l-1) (rest l-2))))
          (else
           #f)))

(define (url-queries-equal? url-1 url-2)
  (let ([q-1 (url-query url-1)]
        [q-2 (url-query url-2)])
    (query-lists-equal? q-1 q-2)))

(define (url-fragments-equal? url-1 url-2)
  (let ([f-1 (url-fragment url-1)]
        [f-2 (url-fragment url-2)])
    (or (and (eq? #f f-1)
             (eq? #f f-2))
        (string=? f-1 f-2))))

(define (urls-equal? url-1 url-2)
  (cond ((string? url-1)
         (urls-equal? (string->url url-1) url-2))
        ((string? url-2)
         (urls-equal? url-1 (string->url url-2)))
        ((and (url? url-1)
              (url? url-2))
         (and (url-schemes-equal? url-1 url-2)
              (url-users-equal? url-1 url-2)
              (url-hosts-equal? url-1 url-2)
              (url-ports-equal? url-1 url-2)
              (url-paths-absolute? url-1 url-2)
              (url-paths-equal? url-1 url-2)
              (url-queries-equal? url-1 url-2)
              (url-fragments-equal? url-1 url-2)))
        (else
         (error "Arguments should be either strings or url? structures."))))

(provide urls-equal?)

(module+ test
  (let ([empty-url (url #f #f #f #f #f (list) (list) #f)])
    (check-true (urls-equal? empty-url empty-url))))
