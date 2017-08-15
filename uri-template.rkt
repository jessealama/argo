#lang racket/base

(module+ test
  (require rackunit))

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

(define (uri-template-parameter-pair? x)
  (and (pair? x)
       (symbol? (car x))))

(define (uri-template-parameters? x)
  (and (list? x)
       (andmap uri-template-parameter-pair? x)))

(define (make-uri-template-parameters . more)
  (cond ((null? more)
         (list))
        ((null? (cdr more))
         (error "No more arguments after:" (car more)))
        (else
         (let ([p (cons (car more) (cdr more))])
           (unless (uri-template-parameter-pair? p)
             (error "Not a URI template parameter pair:" p))
           (cons p (make-uri-template-parameters (rest (rest more))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Evaluation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; uri-template? uri-template-variables? -> url?
(define (expand-uri-template template variables)
  (string->url "http://racket-lang.org"))

(provide expand-uri-template)

(module+ test
  (let* ([template "http://www.example.com/foo{?query,number}"]
         [parameters (list (cons 'query "mycelium")
                           (cons 'number 100))])
    (test-begin
      (check-true (uri-template? template))
      (check-true (uri-template-parameters? parameters))
      (let ([expanded (expand-uri-template template parameters)])
        (test-begin
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
          (let ([query (url-query expanded)])
            (test-begin
              (check-= 2 (length query) 0)
              (let ([q (first query)])
                (test-begin
                  (check-eq? 'query (car q))
                  (check-true (string? (cdr q)))
                  (check-true (string=? "mycelium" (cdr q)))))
              (let ([q (second query)])
                (test-begin
                  (check-eq? 'number (car q))
                  (check-true (string? (cdr q)))
                  (check-true (string=? "100" (cdr q))))))))))))
