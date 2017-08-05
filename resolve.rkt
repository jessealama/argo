#lang racket/base

(require (only-in (file "parameters.rkt")
                  original-schema
                  current-id))

(require net/url-structs)

(require (only-in (file "format.rkt")
                  json-pointer?))

;; jsoin-pointer? jsexpr? -> jsexpr?
(define (resolve-pointer-in-document pointer document)
  document)

; string? -> jsexpr? boolean?
(define (resolve-schema ref)
  (cond ((json-pointer? ref)
         (let ([document (current-schema)])
           (cond ((jsexpr? document)
                  (resolve-pointer-in-document ref document))
                 (else
                  (values #f #f)))))
        (else
         (define url (string->url url/string))
         (define-values (path header) (uri&headers->path&header url (list)))
         (define-values (in out) (connect-uri url))
         (define ok? (start-request in
                                    out
                                    "1.1"
                                    "GET"
                                    path
                                    header))
         (define h (purify-port/log-debug in))
         (define schema/bytes (read-entity/bytes in h))
         (define-values (schema well-formed?) (parse-json-bytes schema/bytes))
         (and (cond ((not well-formed?)
                     (log-error (format "Schema at \"~a\" is malformed." url))
                     (log-error (format "~a" schema/bytes)))
                    (else
                     (valid-wrt-schema? data schema)))
              (valid-w/o? '$ref)))))
