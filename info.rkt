#lang info

(define collection "argo")

(define version "2.0.0")

(define deps
  '("base"
    "rackunit-lib"
    "http"
    "sugar"
    "beautiful-racket-lib"
    "web-server-lib"
    "json-pointer"
    "uri-template"
    "brag"))

(define build-deps
  '("scribble-lib"
    "racket-doc"
    "rackunit-lib"
    "beautiful-racket-lib"))

(define pkg-desc "JSON Schema validator")

(define pkg-authors '("jesse@serverracket.com"))

(define scribblings '(("scribblings/argo.scrbl" ())))

(define raco-commands
  '(("argo"
     (submod argo/command raco)
     "work with JSON Schema"
     #f)))
