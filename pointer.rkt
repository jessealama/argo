#lang racket/base

(module+ test
  (require rackunit))

(require br-parser-tools/lex)
(require (only-in brag/support
                  token
                  apply-lexer
                  exn:fail:parsing?))
(require (only-in racket/list
                  empty?))
(require (only-in (file "pointer-parser.rkt")
                  parse))

(define pointer-lexer
  (lexer
   [(eof)
    eof]
   [#\/
    (token "/")]
   ["~0"
    (token 'NEGATED-0)]
   ["~1"
    (token 'NEGATED-1)]
   [(char-complement (union #\/ #\~))
    (token 'UNESCAPED lexeme)]))

(define (lex-pointer s)
  (apply-lexer pointer-lexer (open-input-string s)))

(define (make-tokenizer port)
  (define (next-token)
    (pointer-lexer port))
  next-token)

(provide make-tokenizer)

(define (json-pointer? x)
  (and (string? x)
       (with-handlers ([exn:fail:parsing? (lambda (e) #f)])
         (begin0
             #t
           (parse (make-tokenizer (open-input-string x)))))))

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
