#lang racket/base

(require json)
(require (only-in (file "../util.rkt")
                  file-content/bytes
                  bytes->string
                  complain-and-die))
(require (only-in (file "../parse.rkt")
                  parse-json-string))
(require (only-in (file "../schema.rkt")
                  json-schema?))
(require (only-in (file "../validate.rkt")
                  adheres-to-schema?))
(require (only-in racket/cmdline
                  command-line))
(require raco/command-name)

(module+ test
  (require rackunit))

(module+ main
  (define quiet-mode? (make-parameter #f))
  (define-values (schema-path instance-path)
    (command-line
     #:program (short-program+command-name)
     #:once-each
     [("--quiet") "Write nothing to stdout."
                  (quiet-mode? #f)]
     #:args (schema-path instance-path)
     (values schema-path instance-path)))
  (unless (file-exists? schema-path)
    (complain-and-die (format "Schema file \"~a\" does not exist." schema-path)))
  (unless (file-exists? instance-path)
    (complain-and-die (format "Instance file \"~a\" does not exist." instance-path)))
  (define (parse-fail err) #f)
  (define schema/bytes (file-content/bytes schema-path))
  (define instance/bytes (file-content/bytes instance-path))
  (define schema/string (bytes->string schema/bytes))
  (define instance/string (bytes->string instance/bytes))
  (when (eq? schema/string #f)
    (complain-and-die (format "Contents of schema at \"~a\" cannot be interpreted as a UTF-8 string." schema-path)))
  (when (eq? instance/string #f)
    (complain-and-die (format "Contents of instance at \"~a\" cannot be interpreted as a UTF-8 string." instance-path)))
  (define-values (schema/jsexpr schema-well-formed?)
    (parse-json-string schema/string))
  (define-values (instance/jsexpr instance-well-formed?)
    (parse-json-string instance/string))
  (unless schema-well-formed?
    (complain-and-die (format "Schema at \"~a\" is not well-formed JSON." schema-path)))
  (unless instance-well-formed?
    (complain-and-die (format "Instance at \"~a\" is not well-formed JSON." instance-path)))
  (unless (json-schema? schema/jsexpr)
    (complain-and-die (format "Schema at \"~a\" is not a JSON schema.")))
  (define adheres? (adheres-to-schema? instance/jsexpr schema/jsexpr))
  (unless (quiet-mode?)
    (display (if adheres?
                 "Validation succeeded."
                 "Validation failed."))
    (newline))
  (exit (if adheres? 0 1)))
