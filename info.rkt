#lang info
(define collection "argo")
(define deps '("base"
               "rackunit-lib"
	       "http"
	       "brag"
	       "sugar"
	       "br-parser-tools-lib"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib" "beautiful-racket-lib"))
(define scribblings '(("scribblings/argo.scrbl" ())))
(define pkg-desc "Argo is a JSON Schema validator.")
(define version "0.1")
(define pkg-authors '("jesse@lisp.sh"))
