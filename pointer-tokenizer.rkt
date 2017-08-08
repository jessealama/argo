#lang racket/base

(require br-parser-tools/lex)
(require (only-in brag/support
                  token
                  apply-lexer))

(define pointer-lexer
  (lexer
   [(eof)
    eof]
   [#\/
    (token "/")]
   ["~0"
    (token "~0")]
   ["~1"
    (token "~1")]
   [(repetition 1 +inf.0 (char-complement (union #\/ #\~)))
    (token 'NO-SLASH-NO-TILDE lexeme)]))

(define (lex-pointer s)
  (apply-lexer pointer-lexer (open-input-string s)))

(define (make-tokenizer port)
  (define (next-token)
    (pointer-lexer port))
  next-token)

(provide make-tokenizer)
