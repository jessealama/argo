#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Interface}

The primary function provided by Argo is adheres-to-schema?.

@defproc[
(adheres-to-schema?
[data jsexpr?]
[schema jsexpr?])
boolean?]
Return @racket[#t] if @racket[_schema] is a JSON Schema and @racket[_data] adheres to @racket[_schema], otherwise @racket[#f].

(Keep in mind that ``JSON Schema'' for Argo means ``version 6 JSON Schema''.)
