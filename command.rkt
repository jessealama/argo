#lang racket/base

(require (only-in json
                  jsexpr?
                  jsexpr->string))
(require (only-in (file "util.rkt")
                  file-content/bytes
                  bytes->string
                  complain-and-die))
(require (only-in (file "parse.rkt")
                  parse-json-string
                  parse-json-file))
(require (only-in (file "schema.rkt")
                  json-schema?))
(require (only-in (file "json.rkt")
                  json-equal?))
(require (only-in (file "validate.rkt")
                  adheres-to-schema?))
(require (only-in json-pointer
                  json-pointer?
                  json-pointer-value))
(require (only-in (file "pp.rkt")
                  json-pretty-print))
(require (only-in (file "oneline.rkt")
                  json-in-one-line))
(require (only-in racket/cmdline
                  command-line))
(require (only-in racket/vector
                  vector-drop))
(require raco/command-name)

;; adapted from Matthew Butterick's pollen
;;
;; thanks, Matthew!

(define quiet-mode? (make-parameter #f))

(module+ raco
  (define command-name (with-handlers ([exn:fail? (λ _ #f)])
                         (vector-ref (current-command-line-arguments) 0)))
  (dispatch command-name))

(define (dispatch command-name)
  (case command-name
    [(#f "help") (handle-help)]
    [("validate") (handle-validate)]
    [("schema") (handle-schema)]
    [("pp") (handle-pretty-print)]
    [("oneline") (handle-oneline)]
    [("equal") (handle-equal)]
    [("point") (handle-point)]
    [("support") (handle-support)]
    [else (handle-unknown command-name)]))

(define (handle-unknown command)
  (displayln (format "`~a` is an unknown Argo command." command))
  (display "These are the available ") ; ... "Argo commands:"
  (handle-help))

(define (handle-help)
  (displayln (format "Argo commands:
help        show this message
validate    validate data against schema
schema      check whether a JSON file is a schema
equal       check whether two JSON files are equal
point       evaluate a JSON Pointer expression
pp          pretty-print JSON
oneline     compress JSON into a single line
support     how to support Argo development")))

(define (handle-validate)
  (define-values (schema-path instance-path)
    (command-line
     #:program "raco argo validate"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "validate" from the command
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
  (cond ((quiet-mode?)
         (exit (if adheres? 0 1)))
        (else
         (display (if adheres?
                      "Validation succeeded."
                      "Validation failed."))
         (newline)
         (exit 0))))

(define (handle-equal)
  (define-values (instance-path-1 instance-path-2)
    (command-line
     #:program "raco argo equal"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "equals" from the command
     #:once-each
     [("--quiet") "Write nothing to stdout."
                  (quiet-mode? #f)]
     #:args (path-1 path-2)
     (values path-1 path-2)))
  (unless (file-exists? instance-path-1)
    (complain-and-die (format "\"~a\" does not exist." instance-path-1)))
  (unless (file-exists? instance-path-2)
    (complain-and-die (format "\"~a\" does not exist." instance-path-2)))
  (define-values (instance-1-jsexpr instance-1-well-formed?)
    (parse-json-file instance-path-1))
  (unless instance-1-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              instance-path-1)))
  (define-values (instance-2-jsexpr instance-2-well-formed?)
    (parse-json-file instance-path-2))
  (unless instance-2-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              instance-path-2)))
  (define equal-json? (json-equal? instance-1-jsexpr instance-2-jsexpr))
  (cond ((quiet-mode?)
         (exit (if json-equal? 0 1)))
        (else
         (display (if equal-json?
                      "JSON files are equal."
                      "JSON files are not equal."))
         (newline)
         (exit 0))))

(define (handle-schema)
  (define schema-path
    (command-line
     #:program "raco argo schema"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "schema" from the command
     #:once-each
     [("--quiet") "Write nothing to stdout."
                  (quiet-mode? #f)]
     #:args (path)
     path))
  (unless (file-exists? schema-path)
    (complain-and-die (format "\"~a\" does not exist." schema-path)))
  (define-values (schema-jsexpr schema-well-formed?)
    (parse-json-file schema-path))
  (unless schema-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              schema-path)))
  (define schema? (json-schema? schema-jsexpr))
  (cond ((quiet-mode?)
         (exit (if schema? 0 1)))
        (else
         (display (if schema?
                      "JSON file is a schema."
                      "JSON file is not a schema."))
         (newline)
         (exit 0))))

(define (handle-point)
  (define-values (json-path json-pointer)
    (command-line
     #:program "raco argo point"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "point" from the command
     #:once-each
     [("--quiet") "Write nothing to stdout."
                  (quiet-mode? #f)]
     #:args (json-path json-pointer-expression)
     (values json-path json-pointer-expression)))
  (unless (file-exists? json-path)
    (complain-and-die (format "\"~a\" does not exist." json-path)))
  (define-values (jsexpr js-well-formed?)
    (parse-json-file json-path))
  (unless js-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              json-path)))
  (unless (json-pointer? json-pointer)
    (complain-and-die (format "\"~a\" is a malformed JSON Pointer expression.")))
  (define failed? #f)
  (define reference
    (with-handlers ([exn:fail? (lambda (e) (set! failed? #t))])
      (json-pointer-value json-pointer jsexpr)))
  (cond ((quiet-mode?)
         (exit (if failed? 1 0)))
        (failed?
         (display "Pointer refers to nothing.")
         (newline)
         (exit 1))
        (else
         (display (json-pretty-print reference))
         (newline)
         (exit 0))))

(define (handle-pretty-print)
  (define-values (json-path)
    (command-line
     #:program "raco argo pp"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "pp" from the command
     #:args (json-path)
     (values json-path)))
  (unless (file-exists? json-path)
    (complain-and-die (format "\"~a\" does not exist." json-path)))
  (define-values (jsexpr js-well-formed?)
    (parse-json-file json-path))
  (unless js-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              json-path)))
  (display (json-pretty-print jsexpr))
  (newline)
  (exit 0))

(define (handle-oneline)
  (define-values (json-path)
    (command-line
     #:program "raco argo oneline"
     #:argv (vector-drop (current-command-line-arguments) 1) ;; drop "oneline" from the command
     #:args (json-path)
     (values json-path)))
  (unless (file-exists? json-path)
    (complain-and-die (format "\"~a\" does not exist." json-path)))
  (define-values (jsexpr js-well-formed?)
    (parse-json-file json-path))
  (unless js-well-formed?
    (complain-and-die (format "\"~a\" is malformed JSON."
                              json-path)))
  (display (json-in-one-line jsexpr))
  (newline)
  (exit 0))

(define (handle-support)
  (displayln "Argo needs your support!")
  (newline)
  (displayln "To support continued development of Argo, please consider")
  (displayln "making a donation. Visit")
  (newline)
  (newline)
  (displayln "          https://gum.co/argojson")
  (newline)
  (newline)
  (displayln "to make a contribution. Thanks!")
  (exit 0))
