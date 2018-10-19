#lang racket/base

(require (only-in (file "regexp.rkt")
                  ecma-262-regexp?)
         (only-in (file "json.rkt")
                  json-non-negative-integer?
                  has-property?
                  property-value
                  object-properties
                  object-values)
         (only-in (file "parse.rkt")
                  parse-json)
         (only-in (file "util.rkt")
                  intersection
                  complain-and-die
                  file-content/bytes
                  bytes->string)
         ejs
         (only-in net/url-string
                  string->url)
         (only-in net/url-structs
                  url-fragment)
         (only-in racket/cmdline
                  command-line)
         (only-in racket/list
                  empty?
                  check-duplicates)
         (only-in (file "format.rkt")
                  uri-reference?
                  json-pointer?)
         racket/contract
         (only-in sugar
                  members-unique?))

(module+ test
  (require rackunit))

(define/contract json-schema-types
  (listof string?)
  (list "object"
	"array"
        "string"
	"boolean"
	"integer"
	"number"
	"null"))

(define/contract (json-schema-type? thing)
  (any/c . -> . boolean?)
  (and (string? thing)
       (list? (member thing json-schema-types string=?))))

(define/contract (acceptable-value-for-type? value)
  (ejsexpr? . -> . boolean?)
  (or (and (ejs-string? value)
           (json-schema-type? value))
      (and (ejs-array? value)
           (members-unique? value)
           (andmap json-schema-type? value))))

(define/contract (acceptable-value-for-multipleOf? value)
  (ejsexpr? . -> . boolean?)
  (and (ejs-number? value)
       (> value 0)))

(define (acceptable-value-for-maximum? value)
  (ejs-number? value))

(define (acceptable-value-for-exclusiveMaximum? value)
  (ejs-number? value))

(define (acceptable-value-for-minimum? value)
  (ejs-number? value))

(define (acceptable-value-for-exclusiveMinimum? value)
  (ejs-number? value))

(define (acceptable-value-for-maxLength? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-minLength? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-pattern? value)
  (and (ejs-string? value)
       (ecma-262-regexp? value)))

(define (acceptable-value-for-items? value)
  (cond ((ejs-array? value)
         (andmap json-schema? value))
        ((ejs-object? value)
         (json-schema? value))
        (else
         #f)))

(define (acceptable-value-for-addditionalItems? value)
  (json-schema? value))

(define (acceptable-value-for-maxItems? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-minItems? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-uniqueItems? value)
  (ejs-boolean? value))

(define (acceptable-value-for-contains? value)
  (json-schema? value))

(define (acceptable-value-for-maxProperties? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-minProperties? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-required? value)
  (and (ejs-array? value)
       (andmap ejs-string? value)
       (members-unique? value)))

(define (acceptable-value-for-properties? value)
  (and (ejs-object? value)
       (andmap json-schema? (object-values value))))

(define (acceptable-value-for-patternProperties? value)
  (and (ejs-object? value)
       (andmap ecma-262-regexp? (map symbol->string (object-properties value)))
       (andmap json-schema? (object-values value))))

(define (acceptable-value-for-additionalProperties? value)
  (json-schema? value))

(define (acceptable-value-for-dependencies? value)
  (and (ejs-object? value)
       (andmap (lambda (x)
                 (or (json-schema? x)
                     (and (ejs-array? x)
                          (andmap ejs-string? x)
                          (members-unique? x))))
               (object-values value))))

(define (acceptable-value-for-propertyNames? value)
  (json-schema? value))

(define (acceptable-value-for-enum? value)
  (and (ejs-array? value)
       (not (empty? value))
       (not (check-duplicates value equal-ejsexprs?))))

(define (acceptable-value-for-const? value)
  (ejsexpr? value))

(define (acceptable-value-for-allOf? value)
  (and (ejs-array? value)
       (not (empty? value))
       (andmap json-schema? value)))

(define (acceptable-value-for-anyOf? value)
  (and (ejs-array? value)
       (not (empty? value))
       (andmap json-schema? value)))

(define (acceptable-value-for-oneOf? value)
  (and (ejs-array? value)
       (not (empty? value))
       (andmap json-schema? value)))

(define (acceptable-value-for-not? value)
  (json-schema? value))

(define (acceptable-value-for-definitions? value)
  (and (ejs-object? value)
       (andmap json-schema?
               (object-values value))))

(define (acceptable-value-for-title? value)
  (ejs-string? value))

(define (acceptable-value-for-description? value)
  (ejs-string? value))

(define (acceptable-value-for-default? value)
  #t)

(define (acceptable-value-for-examples? value)
  (ejs-array? value))

(define (acceptable-value-for-format? value)
  (member value
          (list "date-time"
                "email"
                "hostname"
                "ipv4"
                "ipv6"
                "uri"
                "uri-reference"
                "uri-template"
                "json-pointer")))

(define (acceptable-value-for-$ref? value)
  (and (string? value)
       (let* ([u (string->url value)]
              [f (url-fragment u)])
         (or (eq? #f f)
             (json-pointer? f)))))

(module+ test
  (check-true (acceptable-value-for-$ref? "#/definitions/positiveInteger")))

(define (acceptable-value-for-$schema? value)
  (string? value))

(define json-schema-validators
  (hasheq 'multipleOf acceptable-value-for-multipleOf?
          'maximum acceptable-value-for-maximum?
          'exclusiveMaximum acceptable-value-for-exclusiveMaximum?
          'minimum acceptable-value-for-minimum?
          'exclusiveMinimum acceptable-value-for-exclusiveMinimum?
          'minLength acceptable-value-for-minLength?
          'maxLength acceptable-value-for-maxLength?
          'pattern acceptable-value-for-pattern?
          'items acceptable-value-for-items?
          'additionalItems acceptable-value-for-addditionalItems?
          'maxItems acceptable-value-for-maxItems?
          'minItems acceptable-value-for-minItems?
          'uniqueItems acceptable-value-for-uniqueItems?
          'contains acceptable-value-for-contains?
          'maxProperties acceptable-value-for-maxProperties?
          'minProperties acceptable-value-for-minProperties?
          'required acceptable-value-for-required?
          'properties acceptable-value-for-properties?
          'patternProperties acceptable-value-for-patternProperties?
          'additionalProperties acceptable-value-for-additionalProperties?
          'dependencies acceptable-value-for-dependencies?
          'propertyNames acceptable-value-for-propertyNames?
          'enum acceptable-value-for-enum?
          'const acceptable-value-for-const?
          'type acceptable-value-for-type?
          'allOf acceptable-value-for-allOf?
          'anyOf acceptable-value-for-anyOf?
          'oneOf acceptable-value-for-oneOf?
          'not acceptable-value-for-not?

          ;; metadata validators
          'definitions acceptable-value-for-definitions?
          'title acceptable-value-for-title?
          'description acceptable-value-for-description?
          'default acceptable-value-for-default?
          'examples acceptable-value-for-examples?

          ;; semantic validation
          'format acceptable-value-for-format?

          ;; referring to other schemas
          '$ref acceptable-value-for-$ref?
          '$schema acceptable-value-for-$schema?
          ))

(define json-schema-keywords
  (hash-keys json-schema-validators))

(module+ test
  (define keywords
    (list 'multipleOf
          'maximum
          'exclusiveMaximum
          'minimum
          'exclusiveMinimum
          'maxLength
          'minLength
          'pattern
          'items
          'additionalItems
          'maxItems
          'minItems
          'uniqueItems
          'contains
          'maxProperties
          'minProperties
          'required
          'properties
          'patternProperties
          'additionalProperties
          'dependencies
          'propertyNames
          'enum
          'const
          'type
          'allOf
          'anyOf
          'oneOf
          'not
          'definitions
          'title
          'description
          'default
          'examples
          'format
          '$schema
          '$ref))
  (for ([keyword keywords])
    (check-not-false (member keyword json-schema-keywords)))
  (for ([keyword json-schema-keywords])
    (check-not-false (member keyword keywords))))

(define (json-schema? thing)
  (cond ((not (ejsexpr? thing))
         #f)
        ((ejs-boolean? thing)
         #t)
        ((ejs-object? thing)
         (let* ([properties (object-properties thing)]
                [checkable (intersection properties
                                         json-schema-keywords)])
           (andmap (lambda (keyword)
                     ((hash-ref json-schema-validators keyword)
                      (hash-ref thing keyword)))
                   checkable)))
        (else
         #f)))

(provide json-schema?)

(module+ test

  (test-case "Silly JSON schema type checks"
    (check-false (json-schema? 4)))

  (test-case "Boolean JSON schema checks"
    (check-true (json-schema? #t))
    (check-true (json-schema? #f)))

  (test-case "JSON schema checks")
  (check-false (json-schema? (hasheq "type" "object")))
  (check-false (json-schema? (hasheq 'type #f)))
  (let ([js (hasheq 'type "object")])
    (check-true (ejs-object? js))
    (check-true (has-property? js 'type))
    (check-true (ejs-string? (property-value js 'type)))
    (check-true (json-schema? js)))

  (check-false (json-schema? (hasheq 'type "foo")))

  ;; funky edge case: empty array as type
  (check-true (json-schema? (hasheq 'type
                                    (list))))

  (check-false (json-schema? (hasheq 'type
                                     (list "foo"))))

  ;; single correct value
  (check-true (json-schema? (hasheq 'type
                                    (list "object"))))

  ;; typo
  (check-false (json-schema? (hasheq 'type
                                     (list "objet"))))

  ;; two legimate values
  (check-true (json-schema? (hasheq 'type
                                    (list "object" "integer"))))

  ;; extreme case: all the types
  (check-true (json-schema? (hasheq 'type
                                    json-schema-types)))

  ;; duplicate values (though each, separately, is valid)
  (check-false (json-schema? (hasheq 'type
                                     (list "object" "number" "object"))))

  ;; bogus value along with legit value
  (check-false (json-schema? (hasheq 'type
                                     (list "number" "real"))))

  (define schema-1/jsexper
    (hasheq
     'type "object"
     'items (hasheq
             'foo (hasheq
                   'type "integer"))
     'additionalItems #t))
  (test-case
      "Simple check"
    (check-true (ejsexpr? schema-1/jsexper))
    (check-true (json-schema? (hasheq)))))

(module+ test
  (check-true (json-schema? (hasheq 'type "string"))))

;; Command line application for testing whether a file is
;; a JSON Schema at all

(module+ main
  (define schema-path
    (command-line
     #:program "schema"
     #:args (schema-path)
     schema-path))
  (unless (file-exists? schema-path)
    (complain-and-die (format "Schema file \"~a\" does not exist." schema-path)))
  (define-values (schema/jsexpr schema-well-formed?)
    (parse-json (string->path schema-path)))
  (unless schema-well-formed?
    (complain-and-die (format "Schema at \"~a\" is not well-formed JSON." schema-path)))
  (exit (if (json-schema? schema/jsexpr)
            0
            1)))
