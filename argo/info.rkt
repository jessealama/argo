#lang info

(define scribblings '(("scribblings/argo.scrbl" ())))
(define raco-commands
  '(("argo"
     (submod command raco)
     "work with JSON Schema"
     #f)))
