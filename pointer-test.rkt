#lang racket/base

(require (file "pointer-parser.rkt"))
(require (file "pointer-tokenizer.rkt"))
(require brag/support)

(parse-to-datum (apply-tokenizer-maker make-tokenizer "/foo"))
