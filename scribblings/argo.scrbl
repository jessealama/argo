#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title[#:style "toc"]{Argo: Validate your JSON}
@author[(author+email "Jesse Alama" "jesse@lisp.sh")]

@defmodule[argo]

Argo is a JSON Schema validator. Work with your JSON data knowing that it adheres to some sensible constraints.

Argo is (in this version, anyway) a library. Its main interface is the function adheres-to-schema?. It takes two arguments: a JSON Schema and a JSON document. Its one and only job is to return a boolean value. @racket[#t] means that the document adheres to the schema; @racket[#f] means it does not.

@section{Installation}

To install Argo from the command line, use the raco pkg install command, like so:

@verbatim{raco pkg install argo}

After Argo has been installed, you can keep it up-to-date using raco pkg update:

@verbatim{raco pkg update argo}

@section{Interface}

The primary function provided by Argo is adheres-to-schema?.

@defproc[
(adheres-to-schema?
[data jsexpr?]
[schema jsexpr?])
boolean?]
Return @racket[#t] if @racket[_schema] is a JSON Schema and @racket[_data] adheres to @racket[_schema], otherwise @racket[#f].

@section{Technical information}

@subsection{Semantic validation}

Argo supports all the semantic validation keywords: "date-time", "email", "hostname", "ipv4", "ipv6", "uri", "uri-reference", "uri-template", and "json-pointer".

@subsection{JSON Schema versions}

JSON Schema is a moving target. Thankfully, the target moves slowly. But it *does* move. What does that mean for you? To put it bluntly: a JSON document that's valid today may not be valid tomorrow.

Argo implements JSON Schema version 6 (v6, draft-wright-json-schema*-01) http://json-schema.org/latest/json-schema-validation.html. If you've been working with JSON Schema for a few years, chances are good that you've worked with version 4. (To my knowledge, there was no version 5.) The two are largely the same, but there are some minor differences. Unfortunately, what counts as a "minor difference" is in the eyes of the (human) beholder. While testing Argo I found several schemas on the web, written in the heyday of version 4, that no longer produced the expected results when interpreted as version 6 schemas.

@section{Shortcomings and sorely missing features}

* Hypermedia keywords (base, links, media) are currently not supported. When these properties are encountered on a JSON schema, they are silently ignored. If you work with JSON schema that rely on these features, it will almost certainly not work with Argo. (Meanining: validation will produce many false negatives and maybe even some false positives.)
* Error reporting is missing. If a JSON document is not valid according to a JSON schema, you just get #f. You don't get a description of *why* the document fails validation.
* As of writing, the current version of the JSON Schema specification is 6. Earlier versions of JSON Schema are not supported. Schema that declare themselves to be, say, a v4 JSON Schema may not be treated correctly (that is, according to the v4 rules). If you can, either leave out the $schema keyword or use the value "http://json-schema.org/draft-06/schema#" for $schema.

@section{Further reading}

See also:

* http://json-schema.org

More specifically,

* http://json-schema.org/latest/json-schema-core.html
* http://json-schema.org/latest/json-schema-validation.html
