#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{point}}

The @tt{point} command takes a JSON file and a @hyperlink[#:underline? #f "https://tools.ietf.org/html/rfc6901"]{JSON Pointer} expression as input and outputs the part of the JSON file to which the expression refers.

Run it like this:

@verbatim{
raco argo point data.json expression
}

@section[#:tag "point-exit-code"]{Exit code}

@tt{point} exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly two arguments, @tt{data.json} and @tt{expression}, were supplied to it,}
  @item{@tt{data.json} exists and is a file,}
  @item{@tt{data.json} is well-formed JSON,}
  @item{@tt{expression} is a well-formed JSON Pointer expression, and}
  @item{@tt{expression} refers to something in @tt{data.json}.}
]

If any of these conditions fails, the exit code will be 1.

@section{Options}

@tt{point} accepts no options.
