#lang racket/base

(module+ test
  (require rackunit))

(require (only-in (file "parse.rkt")
                    parse-json-string
                    parse-json-url))

(require (only-in (file "parameters.rkt")
                  original-schema
                  current-id))

(require net/url-structs)

(require (only-in net/url
                  string->url
                  combine-url/relative))

(require (only-in net/url-string
                  url->string))

(require (only-in json-pointer
                  json-pointer?
                  json-pointer-value))

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

; string?|url? string?|#f jsexpr? -> jsexpr? boolean?
(define (resolve-schema-wrt-id ref id document)
  (cond ((string? id)
         (let* ([id/url (string->url id)]
                [combined (combine-url/relative id/url ref)])
           (resolve-schema-wrt-id combined #f document)))
        ((eq? id #f)
         (cond ((string? ref)
                (resolve-schema-wrt-id (string->url ref) id document))
               ((url? ref)
                (define fragment (url-fragment ref))
                (when (string? fragment)
                  (unless (json-pointer? fragment)
                    (error "Fragment part of URL is not a JSON Pointer:" fragment)))
                (cond ((url-has-only-fragment? ref)
                       (values (json-pointer-value fragment document)
                               #t))
                      ((string? (url-host ref))
                       (define url-w/o-fragment
                         (struct-copy url
                                      ref
                                      [fragment #f]))
                       (define-values (schema well-formed?)
                         (parse-json-url url-w/o-fragment))
                       (cond ((not well-formed?)
                              (values #f #f))
                             ((string? fragment)
                              (values (json-pointer-value fragment schema) #f))
                             (else
                              (values schema #t))))))
               (else
                (error "ref should be either a string or a URL." ref))))))

(provide resolve-schema-wrt-id)

(module+ test
  (define geo/str #<<SCHEMA
{
    "id": "http://json-schema.org/geo",
    "$schema": "http://json-schema.org/draft-06/schema#",
    "description": "A geographical coordinate",
    "type": "object",
    "properties": {
        "latitude": { "type": "number" },
        "longitude": { "type": "number" }
    }
}
SCHEMA
  ))

(module+ test
  (require (only-in ejs
                    equal-ejsexprs?))
  (define-values (geo/jsexp geo-ok?)
    (parse-json-string geo/str))
  (check-true geo-ok?)

  ;; commented out because testing these requires making
  ;; an HTTP connection to json-schema.org:
  ;;
  ;; (define-values (resolved-geo resolved-ok?)
  ;;   (resolve-schema-wrt-id "http://json-schema.org/geo" #f (hasheq)))
  ;; (check-true resolved-ok?)
  ;; (check-true (equal-ejsexprs? resolved-geo geo/jsexp))
  )

(module+ test
  ;; https://spacetelescope.github.io/understanding-json-schema/structuring.html
  (define address-schema/str #<<ADDRESS_SCHEMA
{
    "type": "object",
    "properties": {
        "street_address": { "type": "string" },
        "city":           { "type": "string" },
        "state":          { "type": "string" }
    },
    "required": ["street_address", "city", "state"]
}
ADDRESS_SCHEMA
))

(module+ test
  (define full-address-schema/str #<<FULL_SCHEMA
{
  "$schema": "http://json-schema.org/draft-04/schema#",

  "definitions": {
    "address": {
      "type": "object",
      "properties": {
        "street_address": { "type": "string" },
        "city":           { "type": "string" },
        "state":          { "type": "string" }
      },
      "required": ["street_address", "city", "state"]
    }
  },

  "type": "object",

  "properties": {
    "billing_address": { "$ref": "#/definitions/address" },
    "shipping_address": { "$ref": "#/definitions/address" }
  }
}
FULL_SCHEMA
))

(module+ test
  (define-values (address/jsexpr address-ok?)
    (parse-json-string address-schema/str))
  (check-true address-ok?)
  (define-values (full-schema/jsexpr full-schema-ok?)
    (parse-json-string full-address-schema/str))
  (check-true full-schema-ok?)
  (define-values (resolved-value resolved?)
    (resolve-schema-wrt-id "#/definitions/address" #f full-schema/jsexpr))
  (check-true resolved?)
  (check-true (equal-ejsexprs? resolved-value address/jsexpr)))
