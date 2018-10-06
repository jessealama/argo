#lang racket/base

(provide make-tokenizer)

(require brag/support
         racket/contract)

(module+ test
  (require rackunit))

(define (make-tokenizer port)
  (define (next-token)
    (define ejs-lexer
      (lexer-src-pos
       [(eof)
        eof]
       [(union "\n" " " "\t")
        (next-token)]
       [(union "true"
               "false"
               "null")
        (token lexeme lexeme)]
       [(from/to #\" #\")
        (token 'DOUBLE-QUOTED-STRING
               (trim-ends "\"" lexeme "\""))]
       [(:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))
        (token 'DIGITS lexeme)]
       [(:: #\- (:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)))
        (token 'NEGATIVE-DIGITS lexeme)]
       [(:: (:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))
            #\.
            (:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)))
        (token 'DECIMAL-DIGITS lexeme)]
       [(:: #\-
            (:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9))
            #\.
            (:+ (union #\0 #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9)))
        (token 'NEGATIVE-DECIMAL-DIGITS lexeme)]
       [any-char
        (token lexeme lexeme)]))
    (ejs-lexer port))
  next-token)
