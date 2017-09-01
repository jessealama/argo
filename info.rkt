#lang info
(define collection 'multi)
(define version "0.2")
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
