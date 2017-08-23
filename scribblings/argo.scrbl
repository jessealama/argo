#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title[#:style "toc"]{Argo: JSON Schema Validator}
@author[(author+email "Jesse Alama" "jesse@lisp.sh")]

@defmodule[argo]

Argo is a JSON Schema validator. Work with your JSON data knowing that it adheres to some sensible constraints. If you have to work with JSON, even if only occasionally, you may want to consider validating it (that is, checking that is satisfies

Argo is a library that exports only one function: @racket[adheres-to-schema?]. That function takes a JSON Schema and a JSON document and returns a boolean value. @racket[#t] means that the document adheres to the schema; @racket[#f] means it does not.

@include-section["installation.scrbl"]

@include-section["interface.scrbl"]

@include-section["technical.scrbl"]

@include-section["limitations.scrbl"]

@include-section["references.scrbl"]
