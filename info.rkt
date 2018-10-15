#lang info

(define collection "argo")

(define version "1.4.1")

(define deps
  '("base"
    "rackunit-lib"
    "http"
    "sugar"
    "beautiful-racket-lib"
    "web-server-lib"
    "json-pointer"
    "uri-template"
    "ejs"))

(define build-deps
  '("scribble-lib"
    "racket-doc"
    "rackunit-lib"
    "beautiful-racket-lib"))

(define pkg-desc "JSON Schema validator")

(define pkg-authors '("jesse@lisp.sh"))

(define scribblings '(("scribblings/argo.scrbl" ())))

(define raco-commands
  '(("argo"
     (submod argo/command raco)
     "work with JSON Schema"
     #f)))
