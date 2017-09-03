#lang racket/base

(require json)
(require (only-in (file "util.rkt")
                  file-content/bytes
                  bytes->string
                  complain-and-die))
(require (only-in (file "parse.rkt")
                  parse-json-string))
(require (only-in (file "schema.rkt")
                  json-schema?))
(require (only-in (file "validate.rkt")
                  adheres-to-schema?))
(require (only-in racket/cmdline
                  command-line))
(require (only-in racket/vector
                  vector-drop))
(require raco/command-name)

;; adapted from Matthew Butterick's pollen
;;
;; thanks, Matthew!

(module+ raco
  (define command-name (with-handlers ([exn:fail? (λ _ #f)])
                         (vector-ref (current-command-line-arguments) 0)))
  (dispatch command-name))

(define (dispatch command-name)
  (case command-name
    [(#f "help") (handle-help)]
    [("validate") (handle-validate)] ; parses its own args
    [else (handle-unknown command-name)]))

(define (handle-unknown command)
  (displayln (format "`~a` is an unknown Argo command." command))
  (display "These are the available ") ; ... "Argo commands:"
  (handle-help))

(define (handle-help)
  (displayln (format "Argo commands:
help        show this message
validate    validate data against schema")))

(define (handle-validate)
  (define quiet-mode? (make-parameter #f))
  (define-values (schema-path instance-path)
    (command-line
     #:program "raco argo validate"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "validate" from the fron
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
