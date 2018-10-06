#lang racket/base

(provide ejsexpr->bytes
         ejsexpr->string)

(require racket/contract
         racket/string
         racket/match
         racket/pretty
         (file "value.rkt"))

(module+ test
  (require rackunit))

(define/contract (ejsexpr->bytes expr)
  (ejsexpr? . -> . bytes?)
  (string->bytes/utf-8 (ejsexpr->string expr)))

(define/contract (array-items->string items)
  ((listof ejsexpr?) . -> . string?)
  (match items
    [(list)
     ""]
    [(list item)
     (ejsexpr->string item)]
    [(list-rest item more)
     (format "~a,~a"
             (ejsexpr->string item)
             (array-items->string more))]))

(define/contract (object-items->string items)
  ((listof (cons/c symbol? ejsexpr?)) . -> . string?)
  (match items
    [(list)
     ""]
    [(list item)
     (format "\"~a\":~a"
             (symbol->string (car item))
             (ejsexpr->string (cdr item)))]
    [(list-rest item more)
     (format "\"~a\":~a,~a"
             (symbol->string (car item))
             (ejsexpr->string (cdr item))
             (object-items->string more))]))

(define/contract (ejsexpr->string expr)
  (ejsexpr? . -> . non-empty-string?)
  (match expr
    ['null
     "null"]
    [#t
     "true"]
    [#f
     "false"]
    [(? number?)
     (define s
       (parameterize ([pretty-print-exact-as-decimal #t])
         (pretty-format expr)))
     (when (string-contains? s "/")
       (error (format "Number has no finite decimal representation: ~a"
                      expr)))
     s]
    [(? string?)
     (format "\"~a\"" expr)]
    [(? list?)
     (format "[~a]" (array-items->string expr))]
    [(? hash-eq?)
     (format "{~a}" (object-items->string (hash->list expr)))]
    [else
     (error (format "Don't know how to render ~a" expr))]))

(module+ test
  (check-equal? "null"
                (ejsexpr->string 'null))
  (check-equal? "true"
                (ejsexpr->string #t))
  (check-equal? "false"
                (ejsexpr->string #f))
  (check-equal? "3.14"
                (ejsexpr->string #e3.14))
  (check-equal? "1.00000000000000000000000000000000001"
                (ejsexpr->string #e1.00000000000000000000000000000000001)))
