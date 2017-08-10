#lang racket/base

(module+ test
  (require rackunit))

(require json)

(require http/request)

(require (only-in (file "parameters.rkt")
                  original-schema
                  current-id))

(require (only-in (file "parse.rkt")
                  parse-json-bytes))

(require net/url-structs)

(require (only-in net/url
                  string->url
                  combine-url/relative))

(require (only-in net/url-string
                  url->string))

(require (only-in (file "pointer.rkt")
                  json-pointer?
                  pointer-value))

(require (only-in (file "util.rkt")
                  url-has-only-fragment?))

(define (resolve-ref-wrt-id ref id)
  (cond ((string? id)
         (let ([u (string->url id)])
           (cond ((string? ref)
                  (combine-url/relative u ref))
                 ((url? ref)
                  (combine-url/relative u (url->string ref)))
                 (else
                  (error "ref should be either a string or a URL (url?)." ref)))))
        ((eq? id #f)
         (cond ((string? ref)
                (string->url ref))
               ((url? ref)
                ref)
               (else
                (error "ref should be either a string or a URL (url?)." ref))))
        (else
         (error "id should be either a string or false." id))))

(module+ test
  (let* ([url/string "http://foo.bar/schemas/address.json"]
         [url (string->url url/string)])
    (check-equal? url/string
                  (url->string (resolve-ref-wrt-id url/string #f)))
    (check-equal? (string->url "http://foo.bar/schemas/person.json")
                  (resolve-ref-wrt-id "person.json"
                                      url/string))))

; string? string?|#f jsexpr? -> jsexpr?|#f boolean?
(define (resolve-schema-wrt-id ref id document)
  (cond ((string? id)
         (let ([id/url (string->url id)])
           (let ([combined (combine-url/relative id/url ref)])
             (resolve-schema-wrt-id combined #f document))))
        ((json-pointer? ref)
         (cond ((jsexpr? document)
                (resolve-pointer-in-document ref document))
               (else
                (values #f #f))))
        (else
         (define url (string->url ref))
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
         (if well-formed?
             (values schema #t)
             (values #f #f)))))

(provide resolve-schema-wrt-id)

(module+ test
  (define geo/str #<<SCHEMA
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "description": "A geographical coordinate",
    "type": "object",
    "properties": {
        "latitude": { "type": "number" },
        "longitude": { "type": "number" }
    }
}
SCHEMA
  )
  (define geo/jsexp (parse-json-string geo/str))
  (check json-equal?
         (resolve-schema-wrt-id "http://json-schema.org/geo" #f (hasheq))
         geo/jsexp))
