#lang racket/base

(require (only-in (file "json.rkt")
                  json-isomorphic?))

(module+ test
  (require rackunit))

(define (make-empty-schema)
  (hasheq))

(define (induce-schema/nulls documents)
  (set-property (make-empty-schema)
                'type
                "null"))

(define (induce-schema/strings doc)
  (set-property (make-empty-schema)
                'type
                "string"))

(define (induce-schema/numbers documents)
  (set-property (make-empty-schema)
                'type
                (if (andmap json-integer? documents)
                    "integer"
                    "number")))

(define (induce-schema/booleans documents)
  (if (empty? (rest documents))
      (let ([x (first documents)])
        (set-property (make-empty-schema)
                      'const
                      (if (eq? x #t)
                          "true"
                          "false")))
      (set-property (make-empty-schema)
                    'type
                    "boolean")))

(define (induce-schema/arrays documents)
  (let ([lengths (map array-length documents)]
        [base-schema (set-property (make-empty-schema)
                                   'type
                                   "array")])
    (let ([min-length (apply min lengths)]
          [max-length (apply max lengths)])
      (set-property base-schema
                    'items
                    (induce-schema (map array-items documents))))))

(define (induce-schema/objects documents)
  (let ([base-schema (set-property (make-empty-schema)
                                   'type
                                   "object")]
        [properties (object-properties (first documents))])
    ))

;; (listof jsexpr?) -> json-schema?
;;
;; Requires (without checking) that all the documents are isomorphic
;; to each other in the sense of json-isomorphic?
(define (induce-schema/isomorphic documents)
  (if (empty? documents)
      (make-empty-schema)
      (let ([doc (first documents)]
            [more (rest documents)])
        (cond ((json-null? doc)
               (induce-schema/nulls documents))
              ((json-string? doc)
               (induce-schema/strings documents))
              ((json-number? doc)
               (induce-schema/numbers documents))
              ((json-boolean? doc)
               (induce-schema/booleans documents))
              ((json-array? doc)
               (induce-schema/arrays documents))
              ((json-object? doc)
               (induce-schema/objects documents))
              (else
               (error "What kind of JSON data is this?" doc))))))

(define (induce-schema documents)
  (define classes (group-by identity documents json-isomorphic?)))
