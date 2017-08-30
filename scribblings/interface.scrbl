#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Interface}

@defproc[
(json-schema?
[schema any])
boolean?]
Return @racket[#t] if @racket[_schema] is a @racket[jsexpr?] value that counts as a JSON Schema.

``JSON Schema'' for Argo means ``draft 6 JSON Schema'', which was the current version of the JSON Schema specification when Argo was conceived. If you've worked with JSON Schema over the years, chances are good you've become accustomed to draft 4 schemas. They're largely the same, and for many users, they may be indistinguishable; but they're not identical. This means that what passed for a schema in the halcyon days of 2016 may not be a schema in Argo's eyes. (And vice versa: Argo may accept as a schema something that would be rejected according to the draft 4 rules.)

The meatiest function of Argo is @tt{adheres-to-schema?}.

@defproc[
(adheres-to-schema?
[data jsexpr?]
[schema jsexpr?])
boolean?]
Return @racket[#t] if @racket[_schema] is a (draft 6) JSON Schema and @racket[_data] adheres to @racket[_schema], otherwise @racket[#f].

@defproc[
(check-json/schema
[data any]
[schema any])
void]
Returns @racket[void] if (1) @tt{data} is a @racket[jsexpr?] value, (2) @tt{schema} is a JSON Schema, and (3) @tt{data} adheres to @tt{schema}. Otherwise, an exception is thrown. If cases (1) or (2) fail, the exception is an @racket[exn:fail:contract?]; if case (3) fails, the exception is an @racket[exn:fail?] value.
