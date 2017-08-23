#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Technical information}

@section{Semantic validation}

Argo supports all the semantic validation keywords:

@listitems[
  @item{@tt{date-time} (RFC 3399 timestamps, similar to }
  @item{@tt{email}}
  @item{@tt{hostname}}
  @item{@tt{ipv4}}
  @item{@tt{ipv6}}
  @item{@tt{uri}}
  @item{@tt{uri-reference}}
  @item{@tt{uri-template}, and}
  @item{@tt{json-pointer}}
]

@section{JSON Schema versions}

JSON Schema is a moving target. Thankfully, the target moves slowly. But it *does* move. What does that mean for you? To put it bluntly: a JSON document that's valid today may not be valid tomorrow.

Argo implements JSON Schema version 6 (v6, draft-wright-json-schema*-01) http://json-schema.org/latest/json-schema-validation.html. If you've been working with JSON Schema for a few years, chances are good that you've worked with version 4. (To my knowledge, there was no version 5.) The two are largely the same, but there are some minor differences. Unfortunately, what counts as a "minor difference" is in the eyes of the (human) beholder. While testing Argo I found several schemas on the web, written in the heyday of version 4, that no longer produced the expected results when interpreted as version 6 schemas.
