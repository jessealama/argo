#lang racket

(module+ test
  (require rackunit)
  (require br/define)
  (define-macro (let-test BINDINGS EXPR ...)
    #'(let BINDINGS (test-begin EXPR ...)))
  (define-macro (let*-test BINDINGS EXPR ...)
    #'(let* BINDINGS (test-begin EXPR ...))))

(require net/url-structs)
(require br-parser-tools/lex)
(require (only-in net/url-string
                  string->url))
(require (only-in brag/support
                  token
                  apply-lexer
                  exn:fail:parsing?))
(require (only-in racket/list
                  empty?
                  first
                  second
                  rest))
(require (only-in (file "uri-template-parser.rkt")
                  parse))

(define uri-template-lexer
  (lexer
   [(eof)
    eof]
   ["{"
    (token "{" "{")]
   ["}"
    (token "}" "}")]
   [(char-range "0" "9")
    (if (string=? "0" lexeme)
        (token 'ZERO lexeme)
        (token 'NON-ZERO-DIGIT lexeme))]
   [#\.
    (token "." ".")]
   [#\:
    (token ":" ":")]
   [#\?
    (token "?" "?")]
   [#\,
    (token "," ",")]
   [(char-range "A" "z")
    (token 'LETTER lexeme)]
   [(union #\!                          ; %x21
           (char-range #\# #\$)         ; %x23-24
           #\&                          ; %x26
           (char-range "(" ";")         ; %x28-3B
           #\=                          ; %x3D
           (char-range #\? "[")         ; %x3F-5B
           "]"                          ; %x5D
           #\_                          ; %x5F
           (char-range #\a #\z)         ; %x61-7A
           #\~                          ; %x7E

           ;; ucschar
           (char-range #\u00a0 #\ud7ff)
           (char-range #\uf900 #\ufdcf)
           (char-range #\ufdf0 #\uffef)
           (char-range #\U10000 #\U1FFFD)
           (char-range #\U20000 #\U2FFFD)
           (char-range #\U30000 #\U3FFFD)
           (char-range #\U40000 #\U4FFFD)
           (char-range #\U50000 #\U5FFFD)
           (char-range #\U60000 #\U6FFFD)
           (char-range #\U70000 #\U7FFFD)
           (char-range #\U80000 #\U8FFFD)
           (char-range #\U90000 #\U9FFFD)
           (char-range #\UA0000 #\UAFFFD)
           (char-range #\UB0000 #\UBFFFD)
           (char-range #\UC0000 #\UCFFFD)
           (char-range #\UD0000 #\UDFFFD)
           (char-range #\UE1000 #\UEFFFD)

           ;; iprivate
           (char-range #\uE000 #\uF8FF)
           (char-range #\UF0000 #\UFFFFD)
           (char-range #\U100000 #\U10FFFD))
    (token 'SAFE-CHAR lexeme)]))

(define (lex-uri-template s)
  (apply-lexer uri-template-lexer (open-input-string s)))

(module+ test
  (check-not-exn (lambda () (lex-uri-template "http://example.com/~{username}/")))
  (check-not-exn (lambda () (lex-uri-template "http://example.com/dictionary/{term:1}/{term}")))
  (check-not-exn (lambda () (lex-uri-template "http://example.com/search{?q,lang}")))
  (check-not-exn (lambda () (lex-uri-template "http://www.example.com/foo{?query,number}")))
  (check-not-exn (lambda () (lex-uri-template "http://www.example.com/foo{?query,number}"))))

(define (make-tokenizer port)
  (define (next-token)
    (uri-template-lexer port))
  next-token)

(define (parse-uri-template s)
  (syntax->datum (parse (make-tokenizer (open-input-string s)))))

(define (uri-template? x)
  (and (string? x)
       (with-handlers ([exn:fail:parsing? (lambda (e) #f)])
         (begin0
             #t
           (parse-uri-template x)))))

(provide uri-template?)

(module+ test
  (check-true (uri-template? "http://example.com/~{username}/"))
  (check-true (uri-template? "http://example.com/dictionary/{term:1}/{term}"))
  (check-true (uri-template? "http://example.com/search{?q,lang}"))
  (check-true (uri-template? "http://www.example.com/foo{?query,number}"))
  (check-true (uri-template? "http://www.example.com/foo{?query,number}")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Parameters
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (uri-template-parameter-name? x)
  (symbol? x))

(module+ test
  (check-true (uri-template-parameter-name? 'hi))
  (check-false (uri-template-parameter-name? "hi")))

(define (uri-template-parameter-value? x)
  (define (ok/non-list? x)
    (or (and (string? x)
             (not (string=? "" x)))
        (exact-integer? x)))
  (or (ok/non-list? x)
      (and (list? x)
           (not (null? x))
           (andmap ok/non-list? x))))

(module+ test
  (check-true (uri-template-parameter-value? 1))
  (check-true (uri-template-parameter-value? -5))
  (check-true (uri-template-parameter-value? "blue"))
  (check-true (uri-template-parameter-value? (list 4 "hi")))
  (check-false (uri-template-parameter-value? (list (list "hi"))))
  (check-false (uri-template-parameter-value? (list))))

(define (uri-template-parameters? x)
  (and (hash? x)
       (andmap symbol?
               (hash-keys x))
       (andmap uri-template-parameter-value?
               (hash-values x))))

(define (make-uri-template-parameters . more)
  (cond ((null? more)
         (hash))
        ((null? (cdr more))
         (error "No more arguments after:" more))
        (else
         (let ([a (first more)]
               [b (second more)])
           (unless (uri-template-parameter-name? a)
             (error "Invalid URI Template parameter name:" a))
           (unless (uri-template-parameter-value? b)
             (error "Invalid URI Template parameter value:" b))
           (let ([made (apply make-uri-template-parameters (rest (rest more)))])
             (if (hash-has-key? made a)
                 (hash-set made a (append (hash-ref made a) (list b)))
                 (hash-set made a b)))))))

(module+ test
  (check-exn exn:fail?
             (lambda ()
               (make-uri-template-parameters 'a "x" 'a (list "boom")))
             "Repeated key, second time as a list! (Violates principle that the value of a URI Template parameter, if a list, should be flat.)"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; uri-template? uri-template-variables? -> url?
(define (expand-uri-template template variables)
  (unless (uri-template? template)
    (error "Not a URI template:" template))
  (unless (uri-template-parameters? variables)
    (error "Not a suitable set/list of URI Template parameters:" variables))
  (unless (list? template)
    (error "Template should be a list:" template))
  (when (null? template)
    (error "Template should not be the empty list."))
  (string->url "http://racket-lang.org"))

(provide expand-uri-template)

(module+ test
  (let*-test ([template "http://www.example.com/foo{?query,number}"]
              [parameters1 (list (cons 'query "mycelium")
                                 (cons 'number 100))]
              [parameters2 (list (cons 'query "mycelium")
                                 (cons 'number 100))]
              [parameters3 (list (cons 'number 100))]
              [parameters4 (list)]
              [parameters5 (list (cons 'some "pig"))])
    (check-true (uri-template? template))
    (check-true (uri-template-parameters? parameters1))
    (check-true (uri-template-parameters? parameters2))
    (check-true (uri-template-parameters? parameters3))
    (check-true (uri-template-parameters? parameters4))
    (check-true (uri-template-parameters? parameters5))
    (let-test ([expanded (expand-uri-template template parameters1)])
              (check-true (url? expanded))
              (check-true (string=? "http"
                                    (url-scheme expanded)))
              (check-eq? #f
                         (url-user expanded))
              (check-true (string=? "www.example.com"
                                    (url-host expanded)))
              (check-eq? #f
                         (url-port expanded))
              (check-eq? #t
                         (url-path-absolute? expanded))
              (check-= 1 (length (url-path expanded)) 0)
              (check-true (string=? "foo"
                                    (first (url-path expanded))))
              (check-true #f
                          (url-fragment expanded))
              (let-test ([query (url-query expanded)])
                        (check-= 2 (length query) 0)
                        (let-test ([q (first query)])
                                  (check-eq? 'query (car q))
                                  (check-true (string? (cdr q)))
                                  (check-true (string=? "mycelium" (cdr q))))
                        (let-test ([q (second query)])
                                  (check-eq? 'number (car q))
                                  (check-true (string? (cdr q)))
                                  (check-true (string=? "100" (cdr q))))))))
