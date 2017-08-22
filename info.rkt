#lang info
(define collection "argo")
(define deps '("base"
               "rackunit-lib"
	       "mutt"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/argo.scrbl" ())))
(define pkg-desc "Argo is a JSON Schema validator.")
(define version "0.1")
(define pkg-authors '("jesse@lisp.sh"))
