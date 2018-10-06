#lang br/quicklang

(provide read-syntax)

(require (file "grammar.rkt")
         (file "tokenizer.rkt"))

(define (read-syntax path port)
  (define parse-tree (parse path (make-tokenizer port)))
  (define module-datum `(module ejs-module ejs/expander
                          ,parse-tree))
  (datum->syntax #f module-datum))
