#lang racket/base

(provide adheres-to-schema?
         json-schema?
         check-json/schema
         json-pretty-print
         json-in-one-line
         parse-json)

(require (only-in (file "./schema.rkt")
                  json-schema?))
(require (only-in (file "./validate.rkt")
                  adheres-to-schema?
                  check-json/schema))
(require (only-in (file "./pp.rkt")
                  json-pretty-print))
(require (only-in (file "./oneline.rkt")
                  json-in-one-line))
(require (file "./parse.rkt"))

;; Checking at the command line

(module+ main
  (require racket/cmdline
           (only-in (file "util.rkt")
                    file-content/bytes
                    bytes->string))
  (define quiet-mode (make-parameter #f))
  (define-values (schema-path instance-path)
    (command-line
     #:program "argo"
     #:once-each
     [("--quiet") "Write nothing to stdout."
                  (quiet-mode #f)]
     #:args (schema-path instance-path)
     (values schema-path instance-path)))
  (unless (file-exists? schema-path)
    (displayln (format "Schema file \"~a\" does not exist." schema-path))
    (exit 1))
  (unless (file-exists? instance-path)
    (displayln (format "Instance file \"~a\" does not exist." instance-path))
    (exit 1))
  (define (parse-fail err) #f)
  (define schema/bytes (file-content/bytes schema-path))
  (define instance/bytes (file-content/bytes instance-path))
  (define schema/string (bytes->string schema/bytes))
  (define instance/string (bytes->string instance/bytes))
  (when (eq? schema/string #f)
    (displayln (format "Contents of schema at \"~a\" cannot be interpreted as a UTF-8 string." schema-path))
    (exit 1))
  (when (eq? instance/string #f)
    (displayln (format "Contents of instance at \"~a\" cannot be interpreted as a UTF-8 string." instance-path))
    (exit 1))
  (define-values (schema/jsexpr schema-well-formed?)
    (parse-json-string schema/string))
  (define-values (instance/jsexpr instance-well-formed?)
    (parse-json-string instance/string))
  (unless schema-well-formed?
    (displayln (format "Schema at \"~a\" is not well-formed JSON." schema-path))
    (exit 1))
  (unless instance-well-formed?
    (displayln (format "Instance at \"~a\" is not well-formed JSON." instance-path))
    (exit 1))
  (unless (json-schema? schema/jsexpr)
    (displayln (format "Schema at \"~a\" is not a JSON schema."
                       schema-path))
    (exit 1))
  (define adheres? (adheres-to-schema? instance/jsexpr schema/jsexpr))
  (exit (if adheres? 0 1)))
