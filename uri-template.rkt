#lang racket/base

(module+ test
  (require rackunit))

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
    (token 'CURLY-OPEN "{")]
   ["}"
    (token 'CURLY-CLOSE "}")]
   [#\~
    (token 'TILDE "~")]
   [(union #\!                          ; %x21
           (char-range #\# #\$)         ; %x23-24
           #\&                          ; %x26
           (char-range "(" ";")         ; %x28-3B
           #\=                          ; %x3D
           (char-range #\? "[")         ; %x3F-5B
           "]"                          ; %x5D
           #\_                          ; %x5F
           (char-range #\a #\z)         ; %x61-7A
           #\|                          ; %x7E

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
  (check-not-exn (lambda () (lex-uri-template "http://example.com/search{?q,lang}"))))

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; uri-template? uri-template-variables? -> url?
(define (expand-uri-template template variables)
  (string->url "http://racket-lang.org"))

(provide expand-uri-template)
