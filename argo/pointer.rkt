#lang racket/base

(module+ test
  (require rackunit))

(require (only-in json
                  jsexpr?))

(require (only-in (file "json.rkt")
                  json-object?
                  json-array?
                  array-length
                  array-ref
                  empty-array?
                  has-property?
                  property-value))

(require br-parser-tools/lex)
(require (only-in brag/support
                  token
                  apply-lexer
                  exn:fail:parsing?))
(require (only-in racket/list
                  empty?
                  first
                  second
                  rest))
(require (only-in (file "pointer-parser.rkt")
                  parse))
(require (only-in net/url-structs
                  url?
                  url-fragment))
(require (only-in net/url-string
                  string->url))

(define pointer-lexer
  (lexer
   [(eof)
    eof]
   [#\/
    (token "/" #\/)]
   ["~0"
    (token 'NEGATED-0 "~")]
   ["~1"
    (token 'NEGATED-1 "/")]
   [(char-complement (union #\/ #\~))
    (token 'UNESCAPED lexeme)]))

(define (lex-pointer s)
  (apply-lexer pointer-lexer (open-input-string s)))

(define (make-tokenizer port)
  (define (next-token)
    (pointer-lexer port))
  next-token)

(provide make-tokenizer)

(define (parse-json-pointer s)
  (syntax->datum (parse (make-tokenizer (open-input-string s)))))

(define (json-pointer? x)
  (and (string? x)
       (with-handlers ([exn:fail:parsing? (lambda (e) #f)])
         (begin0
             #t
           (parse-json-pointer x)))))

(provide json-pointer?)

(module+ test
  (check-false (json-pointer? " "))

  ;; examples copied from https://tools.ietf.org/html/rfc6901
  (check-true (json-pointer? ""))
  (check-true (json-pointer? "/foo"))
  (check-true (json-pointer? "/foo/0"))
  (check-true (json-pointer? "/"))
  (check-true (json-pointer? "/a~1b"))
  (check-true (json-pointer? "/c%d"))
  (check-true (json-pointer? "/e^f"))
  (check-true (json-pointer? "/g|h"))
  (check-true (json-pointer? "/i\\j"))
  (check-true (json-pointer? "/k\"l"))
  (check-true (json-pointer? "/ "))
  (check-true (json-pointer? "/m~0n"))
)

(define (json-pointer/uri-fragment? x)
  (cond ((url? x)
         (json-pointer? (url-fragment x)))
        ((string? x)
         (json-pointer? (url-fragment (string->url x))))
        (else
         #f)))

(module+ test
  (check-true (json-pointer/uri-fragment? "#/definitions/foo"))
  (check-true (json-pointer/uri-fragment? (string->url "http://schema.foo.com/main#/definitions/nice")))
  (check-false (json-pointer/uri-fragment? "/definitions/foo")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; json-pointer? jsexpr?
(define (pointer-value jp doc)
  (unless (json-pointer? jp)
    (error "Not a JSON Pointer." jp))
  (unless (jsexpr? doc)
    (error "Not a JSON value."))
  (unless (json-object? doc)
    (error "Not a JSON object."))
  (define pointer (parse-json-pointer jp))
  (unless (list? pointer)
    (error (format "Result of parsing a JSON pointer (~a) should be a list." jp) pointer))
  (define (find-value steps document)
    (if (empty? steps)
        document
        (let ([step (first steps)])
          (unless (eq? step #\/)
            (error "Expected a slash." step))
          (when (empty? (rest steps))
            (error "Slash followed by nothing!"))
          (let ([next-step (second steps)])
            (unless (list? next-step)
              (error "Not a list:" next-step))
            (when (empty? next-step)
              (error "Empty next step!"))
            (let ([next-step-head (first next-step)]
                  [next-step-tail (rest next-step)])
              (unless (eq? next-step-head 'reference-token)
                (error "Expected the reference-token symbol." next-step-head))
              (unless (andmap string? next-step-tail)
                (error "reference-point should contain a list of strings" next-step-tail))
              (let ([property-name (foldl (lambda (a b)
                                            (format "~a~a" b a))
                                          ""
                                          next-step-tail)])
                (cond ((json-object? document)
                       (unless (has-property? document property-name)
                         (error (format "Document does not have property \"~a\"." property-name)
                                document))
                       (find-value (rest (rest steps))
                                   (property-value document property-name)))
                      ((json-array? document)
                       (let ([len (array-length document)])
                         (cond ((string=? property-name "0")
                                (when (empty-array? document)
                                  (error "Empty array; cannot grab the 0th element."))
                                (find-value (rest (rest steps))
                                            (array-ref document 0)))
                               ((regexp-match? "^[1-9][0-9]*$" property-name)
                                (let ([index (string->number property-name)])
                                  (when (<= len index)
                                    (error (format "Index ~a out of bounds (array contains only ~a items)." index len) document))
                                  (find-value (rest (rest steps))
                                              (array-ref document index))))
                               ((string=? property-name "-")
                                (error "Minus character encountered."))
                               (else
                                (error (format "Cannot handle array index \"~a\" for current array." property-name) document)))))
                      (else
                       (error "A JSON object or array is needed." document)))))))))
  (find-value (rest pointer) doc))

(provide pointer-value)

(module+ test
  (define sample-doc/str #<<SAMPLE
 {
      "foo": ["bar", "baz"],
      "": 0,
      "a/b": 1,
      "c%d": 2,
      "e^f": 3,
      "g|h": 4,
      "i\\j": 5,
      "k\"l": 6,
      " ": 7,
      "m~n": 8
   }
SAMPLE
    ))

(module+ test
  (define-values (sample-doc/jsexpr sample-ok?)
    (parse-json-string sample-doc/str))
  (check-true sample-ok?)
  (require (only-in (file "parse.rkt")
                    parse-json-string))
  (require (only-in (file "json.rkt")
                    json-equal?
                    json-string
                    json-number
                    json-array))
  (check json-equal?
         (pointer-value "" sample-doc/jsexpr)
         sample-doc/jsexpr)
  (check json-equal?
         (pointer-value "/foo" sample-doc/jsexpr)
         (json-array (json-string "bar")
                     (json-string "baz")))
  (check json-equal?
         (pointer-value "/foo/0" sample-doc/jsexpr)
         (json-string "bar"))
  (check json-equal?
         (pointer-value "/" sample-doc/jsexpr)
         (json-number 0))
  (check json-equal?
         (pointer-value "/a~1b" sample-doc/jsexpr)
         (json-number 1))
  (check json-equal?
         (pointer-value "/c%d" sample-doc/jsexpr)
         (json-number 2))
  (check json-equal?
         (pointer-value "/e^f" sample-doc/jsexpr)
         (json-number 3))
  (check json-equal?
         (pointer-value "/g|h" sample-doc/jsexpr)
         (json-number 4))
  (check json-equal?
         (pointer-value "/i\\j" sample-doc/jsexpr)
         (json-number 5))
  (check json-equal?
         (pointer-value "/k\"l" sample-doc/jsexpr)
         (json-number 6))
  (check json-equal?
         (pointer-value "/ " sample-doc/jsexpr)
         (json-number 7))
  (check json-equal?
         (pointer-value "/m~0n" sample-doc/jsexpr)
         (json-number 8)))
