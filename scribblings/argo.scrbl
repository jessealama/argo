#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title[#:style "toc"]{Argo: Validate your JSON}
@author[(author+email "Jesse Alama" "jesse@lisp.sh")]

@defmodule[argo]

Argo is a JSON Schema validator. Work with your JSON data knowing that it adheres to some sensible constraints.

Argo is (in this version, anyway) a library. Its main interface is the function adheres-to-schema?. It takes two arguments: a JSON Schema and a JSON document. Its one and only job is to return a boolean value. @racket[#t] means that the document adheres to the schema; @racket[#f] means it does not.

@include-section["installation.scrbl"]

@include-section["interface.scrbl"]

@include-section["technical.scrbl"]

@include-section["limitations.scrbl"]

@include-section["references.scrbl"]
