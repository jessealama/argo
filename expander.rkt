#lang br/quicklang

(require (for-syntax racket/base))

(define-macro (ejs-mb PARSE-TREE)
  #'(#%module-begin
     PARSE-TREE))

(provide (rename-out [ejs-mb #%module-begin]))

(define-macro (ejsexprs EXPR ...)
  #'(list EXPR ...))

(provide ejsexprs)

(define-macro (ejsexpr WHATEVER)
  #'WHATEVER)

(provide ejsexpr)

(define-macro (null EXPR)
  #''null)

(provide null)

(define-macro-cases boolean
  [(boolean "true") #'#t]
  [(boolean "false") #'#f])

(provide boolean)

(define-macro (number EXPR)
  #'(string->number EXPR
                    10
                    'number-or-false
                    'decimal-as-exact))

(provide number)

(define-macro (array "[" ITEMS ... "]")
  #'(list (remove "," (list ITEMS ...))))

(provide array)

(define (firsts l)
  (match l
    [(list)
     (error "Cannot take firsts of an empty list!")]
    [(list x)
     (list x)]
    [(list x y)
     (list x)]
    [(list-rest x y t)
     (cons x (firsts t))]))

(define (seconds l)
  (match l
    [(list)
     (error "Cannot take seconds of an empty list!")]
    [(list x)
     (error "Cannot take seconds of a single-element list!")]
    [(list x y)
     (list y)]
    [(list-rest x y t)
     (cons y (seconds t))]))

(require racket/hash)

(define-macro (object "{" ITEMS ... "}")
  #'(apply hash-union (remove* (list ",") (list ITEMS ...))))

(provide object)

(define-macro (object-item PROP ":" EXPR)
  #'(hasheq PROP EXPR))

(provide object-item)

(define-macro (string S)
  #'(string-trim S "\""))

(provide string)
