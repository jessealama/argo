#lang info

(define collection "argo")

(define version "0.9.4")

(define deps
  '("base"
    "rackunit-lib"
    "http"
    "brag"
    "sugar"
    "br-parser-tools-lib"))

(define build-deps
  '("scribble-lib"
    "racket-doc"
    "rackunit-lib"
    "beautiful-racket-lib"))

(define pkg-desc "Argo is a JSON Schema validator.")

(define pkg-authors '("jesse@lisp.sh"))

(define scribblings '(("scribblings/argo.scrbl" ())))

(define raco-commands
  '(("argo"
     (submod argo/command raco)
     "work with JSON Schema"
     #f)))
