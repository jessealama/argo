#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Running Argo}

Argo can be executed as a command-line tool using @tt{raco}. This section discusses the five available commands: @tt{validate}, @tt{schema}, @tt{pp}, @tt{point}, and @tt{equal}.

@include-section["command-validate.scrbl"]

@include-section["command-schema.scrbl"]

@include-section["command-pp.scrbl"]

@include-section["command-oneline.scrbl"]

@include-section["command-point.scrbl"]

@include-section["command-equal.scrbl"]
