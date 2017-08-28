#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Technical information}

@section{Semantic validation}

Argo supports all the semantic validation keywords:

@itemlist[
  @item{@tt{date-time} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc3339"]{RFC 3399})}
  @item{@tt{email} (@hyperlink[#:underline? #f "http://tools.ietf.org/html/rfc5322"]{RFC 5322})}
  @item{@tt{hostname} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc1034"]{RFC 1034})}
  @item{@tt{ipv4} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc2673"]{RFC 2673})}
  @item{@tt{ipv6} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc2373"]{RFC 2373})}
  @item{@tt{uri} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc3986"]{RFC 3986})}
  @item{@tt{uri-reference} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc3986"]{ditto})}
  @item{@tt{uri-template} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc6570"]{RFC 6570}), and}
  @item{@tt{json-pointer} (@hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc6901"]{RFC 6901})}
]

@section{JSON Schema versions}

JSON Schema is a moving target. Thankfully, the target moves slowly. But it @italic{does} move. What does that mean for you? To put it bluntly: a JSON document that's valid today may not be valid tomorrow.

Argo implements JSON Schema version 6 (codename ``draft-wright-json-schema-validation-01''). The official homepage for specification that Argo follows is @hyperlink[#:underline? #f "http://json-schema.org/latest/json-schema-validation.html"]{here}. That version was released on April 21, 2017.  If you've been working with JSON Schema for a few years, chances are good that you've worked with version 4. The two versions are largely the same, but there are some minor differences. Unfortunately, what counts as a ``minor difference'' is in the eyes of the beholder. While testing Argo I found several schemas on the web, written in the heyday of version 4---including some on the JSON Schema homepage---that no longer produced the expected results when interpreted as version 6 schemas. They had to be updated. It may very well be possible that you'll need to update your JSON Schemas, too.
