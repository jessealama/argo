#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Running Argo}

Argo can be executed as a command-line tool using @tt{raco}. This section discusses the two available commands: @tt{validate} and @tt{equal}.

@include-section["command-validate.scrbl"]

@include-section["command-equal.scrbl"]
