#lang scribble/manual

@require[@for-label[racket/base json]]

@title{Library interface}

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

@defproc[
(json-equal?
[data-1 jsexpr?]
[data-2 jsexpr?])
boolean]
Returns @racket[#t] if @tt{data-1} and @tt{data-2} represent equal JSON objects.

Equality of two JSON documents @tt{doc-1} and @tt{doc-2} is defined as follows: @tt{doc-1} and @tt{doc-2} have the same type (both are JSON objects, both are JSON strings, etc.) and adhere to the type-specific rules for equality, which are:

@itemlist[
  @item{two strings are equal is they are equal as Unicode strings (codepoint-for-codepoint equal sequences)}
  @item{two null values are equal unconditionally}
  @item{two number values are equal if they are mathematically equal representations of numbers in decimal notation}
  @item{two objects are equal if they have precisely the same keys (which are JSON strings) and, for each key, their corresponding values are equal, and}
  @item{two arrays are equal if they have the same length and if, for each  index, the value of the first array, at that index, is equal to the value at that index of the second array, at that index.}
]

@defproc[
(json-pretty-print
[data jsexpr?])
string?]
Returns a string representation of @tt{data} that is, well, pretty.

@defproc[
(json-pointer-value
[data jsexpr?]
[expr string?])
jsexpr?]
Returns the part of @tt{expr} that the @hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc6901"]{JSON Pointer} expression @tt{expr} refers to.

If @tt{expr} is a malformed JSON Pointer expression, or refers to nothing in @tt{data}, an exception will be raised.
