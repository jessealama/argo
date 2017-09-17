#lang racket/base

(require (only-in json
                  jsexpr?)
         (only-in sugar
                  members-unique?)
         (only-in racket/list
                  check-duplicates)
         (only-in (file "json.rkt")
                  json-string
                  json-number?
                  json-non-negative-integer?
                  json-boolean?
                  json-object?
                  json-string?
                  json-array?
                  empty-array?
                  array-items
                  has-property?
                  property-value
                  object-properties
                  object-values
                  json-equal?)
         (only-in net/url-string
                  string->url)
         (only-in net/url-structs
                  url-fragment)
         (only-in (file "regexp.rkt")
                  ecma-262-regexp?)
         (only-in (file "util.rkt")
                  intersection
                  complain-and-die
                  file-content/bytes
                  bytes->string)
         (only-in racket/cmdline
                  command-line)
         (only-in (file "parse.rkt")
                  parse-json)
         (only-in (file "format.rkt")
                  uri-reference?
                  json-pointer?))

(module+ test
  (require rackunit))

(define json-schema-types
  (list "object"
	"array"
        "string"
	"boolean"
	"integer"
	"number"
	"null"))

(define (json-schema-type? thing)
  (list? (member thing json-schema-types)))

(define (acceptable-value-for-type? value)
  (cond ((json-string? value)
         (json-schema-type? value))
        ((json-array? value)
         (and (members-unique? value)
              (andmap json-schema-type? value)))
        (else
         #f)))

(define (acceptable-value-for-multipleOf? value)
  (cond ((json-number? value)
         (> value 0))
        (else
         #f)))

(define (acceptable-value-for-maximum? value)
  (json-number? value))

(define (acceptable-value-for-exclusiveMaximum? value)
  (json-boolean? value))

(define (acceptable-value-for-minimum? value)
  (json-number? value))

(define (acceptable-value-for-exclusiveMinimum? value)
  (json-number? value))

(define (acceptable-value-for-maxLength? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-minLength? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-pattern? value)
  (cond ((json-string? value)
         (ecma-262-regexp? value))
        (else
         #f)))

(define (acceptable-value-for-items? value)
  (cond ((json-array? value)
         (andmap json-schema? (array-items value)))
        ((json-object? value)
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
  (json-boolean? value))

(define (acceptable-value-for-contains? value)
  (json-schema? value))

(define (acceptable-value-for-maxProperties? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-minProperties? value)
  (json-non-negative-integer? value))

(define (acceptable-value-for-required? value)
  (and (json-array? value)
       (andmap json-string? value)
       (members-unique? value)))

(define (acceptable-value-for-properties? value)
  (cond ((json-object? value)
         (andmap json-schema? (object-values value)))
        (else
         #f)))

(define (acceptable-value-for-patternProperties? value)
  (cond ((json-object? value)
         (and (andmap ecma-262-regexp? (map symbol->string (object-properties value)))
              (andmap json-schema? (object-values value))))
        (else
         #f)))

(define (acceptable-value-for-additionalProperties? value)
  (json-schema? value))

(define (acceptable-value-for-dependencies? value)
  (cond ((json-object? value)
         (andmap (lambda (x)
                   (or (json-schema? x)
                       (and (json-array? x)
                            (andmap json-string? x)
                            (members-unique? x))))
                 (object-values value)))
        (else
         #f)))

(define (acceptable-value-for-propertyNames? value)
  (json-schema? value))

(define (acceptable-value-for-enum? value)
  (cond ((json-array? value)
         (and (not (empty-array? value))
              (not (check-duplicates value json-equal?))))
        (else
         #f)))

(define (acceptable-value-for-const? value)
  #t)

(define (acceptable-value-for-allOf? value)
  (cond ((json-array? value)
         (and (not (empty-array? value))
              (andmap json-schema? value)))
        (else
         #f)))

(define (acceptable-value-for-anyOf? value)
  (cond ((json-array? value)
         (and (not (empty-array? value))
              (andmap json-schema? value)))
        (else
         #f)))

(define (acceptable-value-for-oneOf? value)
  (cond ((json-array? value)
         (and (not (empty-array? value))
              (andmap json-schema? value)))
        (else
         #f)))

(define (acceptable-value-for-not? value)
  (json-schema? value))

(define (acceptable-value-for-definitions? value)
  (and (json-object? value)
       (andmap json-schema?
               (object-values value))))

(define (acceptable-value-for-title? value)
  (json-string? value))

(define (acceptable-value-for-description? value)
  (json-string? value))

(define (acceptable-value-for-default? value)
  #t)

(define (acceptable-value-for-examples? value)
  (json-array? value))

(define (acceptable-value-for-format? value)
  (member value
          (map json-string
               (list "date-time"
                     "email"
                     "hostname"
                     "ipv4"
                     "ipv6"
                     "uri"
                     "uri-reference"
                     "uri-template"
                     "json-pointer"))))

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
  (cond ((not (jsexpr? thing))
         #f)
        ((json-boolean? thing)
         #t)
        ((json-object? thing)
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
    (check-true (json-object? js))
    (check-true (has-property? js 'type))
    (check-true (json-string? (property-value js 'type)))
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
    (check-true (jsexpr? schema-1/jsexper))
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
