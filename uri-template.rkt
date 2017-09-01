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
