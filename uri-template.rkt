#lang racket

(module+ test
  (require rackunit)
  (require br/define)
  (require (only-in (file "util.rkt")
                    urls-equal?))
  (define-macro (let-test BINDINGS EXPR ...)
    #'(let BINDINGS (test-begin EXPR ...)))
  (define-macro (let*-test BINDINGS EXPR ...)
    #'(let* BINDINGS (test-begin EXPR ...))))

(require net/url-structs)
(require br-parser-tools/lex)
(require (only-in net/url-string
                  string->url))
(require brag/support)
(require (only-in racket/list
                  empty?
                  first
                  second
                  rest))
(require (only-in (file "uri-template-expression-parser.rkt")
                  parse))

(define uri-template-lexer
  (lexer
   [(eof)
    eof]
   [(from/to "{" "}")
    (token 'EXPRESSION lexeme)]
   [(repetition 1 +inf.0
                (union #\!                         ; %21
                       (char-range #\# #\$)        ; %x23-24
                       #\&                         ; %x26
                       (char-range "(" ";")        ; %x28-3B
                       #\=                         ; %x3D
                       (char-range #\? "[")        ; %x3F-5B
                       "]"                         ; %x5D
                       #\_                         ; %x5F
                       (char-range #\a #\z)        ; %x61-7A
                       #\~                         ; %x7E

                       ;; ucschar production
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

                       ;; iprivate production
                       (char-range #\uE000 #\uF8FF)
                       (char-range #\UF0000 #\UFFFFD)
                       (char-range #\U100000 #\U10FFFD)))
    (token 'TEXT lexeme)]))

(define (lex-uri-template s)
  (unless (string? s)
    (error "Cannot lex a non-string:" s))
  (apply-lexer uri-template-lexer s))

(module+ test
  (check-exn exn:fail:read? (lambda () (lex-uri-template "hi{")))
  (let-test ([template "http://example.com/~{username}/"])
    (check-not-exn (lambda () (lex-uri-template template)))
    (let-test ([lexed (lex-uri-template template)])
      (check-= 3 (length lexed) 0 (format "~s" lexed))))
  (let-test ([template "http://example.com/dictionary/{term:1}/{term}"])
    (check-not-exn (lambda () (lex-uri-template template)))
    (let-test ([lexed (lex-uri-template template)])
      (check-= 4 (length lexed) 0)))
  (let-test ([template "http://example.com/search{?q,lang}"])
    (check-not-exn (lambda () (lex-uri-template template)))
    (let-test ([lexed (lex-uri-template template)])
      (check-= 2 (length lexed) 0))))

(define (text-token? token)
  (eq? 'TEXT (token-struct-type token)))

(define (expression-token? token)
  (eq? 'EXPRESSION (token-struct-type token)))

(define uri-template-expression-lexer
  (lexer
   [(eof)
    eof]
   ["{"
    (token "{" "{")]
   [#\+
    (token "+" "+")]
   [#\#
    (token "#" "#")]
   [#\.
    (token "." ".")]
   [#\/
    (token "/" "/")]
   [#\;
    (token ";" ";")]
   [#\?
    (token "?" "?")]
   [#\&
    (token "&" "&")]
   [#\=
    (token "=" "=")]
   [#\,
    (token "," ",")]
   [#\!
    (token "!" "!")]
   [#\@
    (token "@" "@")]
   ["|"
    (token "|" "|")]
   [#\_
    (token "_" "_")]
   [#\*
    (token "*" "*")]
   [#\:
    (token ":" ":")]
   [(:seq "%" (:= 2 (union (char-range "0" "9")
                           (char-range "a" "f")
                           (char-range "A" "F"))))
    (token 'PCT-ENCODED lexeme)]
   [(:seq (char-range "1" "9")
          (:* (char-range "0" "9")))
    (token 'NUMBER lexeme)]
   [(char-range "A" "z")
    (token 'LETTER lexeme)]
   ["}"
    (token "}" "}")]))

(define (lex-uri-template-expression s)
  (unless (string? s)
    (error "Cannot lext a non-string:" s))
  (apply-lexer uri-template-expression-lexer
               (open-input-string s)))

(module+ test
  (check-not-exn (lambda () (lex-uri-template-expression "{username}")))
  (check-not-exn (lambda () (lex-uri-template-expression "{term:1}")))
  (check-not-exn (lambda () (lex-uri-template-expression "{?q,lang}")))
  (check-not-exn (lambda () (lex-uri-template-expression "{?query,number}"))))

(define (make-expression-tokenizer port)
  (define (next-token)
    (uri-template-expression-lexer port))
  next-token)

(define (parse-uri-template-expression s)
  (syntax->datum (parse (make-expression-tokenizer (open-input-string s)))))

(define (uri-template-expression? x)
  (and (string? x)
       (with-handlers ([exn:fail:parsing? (lambda (e) #f)])
         (begin0
             #t
           (parse-uri-template-expression x)))))

(provide uri-template-expression?)

(define (uri-template? x)
  (and (string? x)
       (with-handlers ([exn:fail:read? (lambda (e) #f)])
         (let ([lexed-template (lex-uri-template x)])
           (let ([expression-tokens (filter expression-token? lexed-template)])
             (let ([expressions (map token-struct-val expression-tokens)])
               (andmap uri-template-expression? expressions)))))))

(provide uri-template?)

(module+ test
  (check-true (uri-template? "http://example.com/~{username}/"))
  (check-true (uri-template? "http://example.com/dictionary/{term:1}/{term}"))
  (check-true (uri-template? "http://example.com/search{?q,lang}"))
  (check-true (uri-template? "http://www.example.com/foo{?query,number}"))
  (check-false (uri-template? "hi{"))
  (check-true (uri-template? "")))

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
  (or (and (list? x)
           (andmap ok/non-list? x))
      (ok/non-list? x)))

(module+ test
  (check-true (uri-template-parameter-value? 1))
  (check-true (uri-template-parameter-value? -5))
  (check-true (uri-template-parameter-value? "blue"))
  (check-true (uri-template-parameter-value? (list 4 "hi")))
  (check-false (uri-template-parameter-value? (list (list "hi"))))
  (check-true (uri-template-parameter-value? (list))))

(define (uri-template-parameters? x)
  (and (hash? x)
       (andmap symbol?
               (hash-keys x))
       (andmap uri-template-parameter-value?
               (hash-values x))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(struct expression (operator variables))

(define (has-operator? expr)
  (not (eq? #f (expression-operator expr))))

(define (variable-list->list varlist)
  (match varlist
    [(list) (list)]
    [(list-rest "," more)
     (variable-list->list more)]
    [(list-rest 'varspec (list 'varname varchars) more)
     (cons (foldr (lambda (a b)
                    (format "~a~a" a b))
                  ""
                  (map second varchars))
           (variable-list->list more))]))

(module+ test
  (let*-test ([data (list
                     '(varspec
                       (varname
                        (varchar "q")
                        (varchar "u")
                        (varchar "e")
                        (varchar "r")
                        (varchar "y")))
                     ","
                     '(varspec
                       (varname
                        (varchar "n")
                        (varchar "u")
                        (varchar "m")
                        (varchar "b")
                        (varchar "e")
                        (varchar "r"))))]
              [answer (variable-list->list data)])
    (check-true (expression? answer))
    (check-true (has-operator? answer))
    (check-true (string=? "?" (expression-operator answer)))
    (let-test ([vars (expression-variables answer)])
      (check-true (list? vars))
      (check-= 2 (length vars) 0)
      (check-true (string? (first vars)))
      (check-true (string=? "query" (first vars)))
      (check-true (string? (second vars)))
      (check-true (string=? "number" (second vars))))))

; list? -> expression?
(define (expression-datum->expression datum)
  (match datum
    [(list 'expression "{" expr-body "}")
     (match expr-body
       [(list 'variable-list varspecs)
        (expression #f (variable-list->list varspecs))]
       [(list (list 'operator op) (list 'variable-list varspecs))
        (expression op (variable-list->list varspecs))])]))

(module+ test)

(define (expand-token token template-variables)
  (cond ((text-token? token)
         (token-struct-val token))
        ((expression-token? token)
         (let ([val (token-struct-val token)])
           (let ([parsed (parse-uri-template-expression val)])
             (log-error "parsed = ~s" parsed)
             val)))
        (else
         (error "Unhandled token:" token))))

;; uri-template? uri-template-variables? -> string?
(define (expand-uri-template template variables)
  (unless (string? template)
    (error "Template is not a string:" template))
  (unless (uri-template-parameters? variables)
    (error "Not a suitable set/list of URI Template parameters:" variables))
  (let ([lexed-template (lex-uri-template template)])
    (let ([expanded (map (lambda (tok) (expand-token tok variables))
                         (lex-uri-template template))])
      (foldr (lambda (a b) (format "~a~a" a b))
             ""
             expanded))))

(provide expand-uri-template)

(module+ test
  (let*-test ([template "http://www.example.com/foo{?query,number}"]
              [parameters-1 (hash 'query "mycelium"
                                  'number 100)]
              [answer-1 "http://www.example.com/foo?query=mycelium&number=100"]
              [parameters-2 (hash 'query "mycelium")]
              [answer-2 "http://www.example.com/foo?query=mycelium"]
              [parameters-3 (hash 'number 100)]
              [answer-3 "http://www.example.com/foo?number=100"]
              [parameters-4 (hash)]
              [answer-4 "http://www.example.com/foo"]
              [parameters-5 (hash 'some "pig")]
              [answer-5 "http://www.example.com/foo"])
    (check-true (uri-template? template))
    (check-true (uri-template-parameters? parameters-1))
    (check-true (uri-template-parameters? parameters-2))
    (check-true (uri-template-parameters? parameters-3))
    (check-true (uri-template-parameters? parameters-4))
    (check-true (uri-template-parameters? parameters-5))
    (let-test ([expanded-1 (expand-uri-template template parameters-1)])
      (check-true (string? expanded-1))
      (check-true (urls-equal? expanded-1 answer-1)))
    (let-test ([expanded-2 (expand-uri-template template parameters-2)])
      (check-true (string? expanded-2))
      (check-true (urls-equal? expanded-2 answer-2)))
    (let-test ([expanded-3 (expand-uri-template template parameters-3)])
      (check-true (string? expanded-3))
      (check-true (urls-equal? expanded-3 answer-3)))
    (let-test ([expanded-4 (expand-uri-template template parameters-4)])
      (check-true (string? expanded-4))
      (check-true (urls-equal? expanded-4 answer-4)))
    (let-test ([expanded-5 (expand-uri-template template parameters-5)])
      (check-true (string? expanded-5))
      (check-true (urls-equal? expanded-5 answer-5)))))
