#lang scribble/manual

@require[@for-label[racket/base
		    json
		    argo]]

@title[#:style "toc"]{Argo: JSON Schema Adventures}
@author[(author+email "Jesse Alama" "jesse@lisp.sh")]

@defmodule[argo]

Argo is a JSON Schema validator. Work with your JSON data knowing that it adheres to some sensible constraints. If you have to work with JSON, even if only occasionally, you may want to consider validating it (that is, checking that is satisfies the constraints specified by the schema).

@include-section["installation.scrbl"]

@include-section["running.scrbl"]

@include-section["interface.scrbl"]

@include-section["technical.scrbl"]

@include-section["limitations.scrbl"]

@include-section["references.scrbl"]
