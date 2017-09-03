#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{equal}}

The @tt{equal} command takes a two JSON files as input and checks that they represent identical JSON content.

Run it like this:

@verbatim{
raco argo equal json-1.json json-2.json
}

Depending on whether the contents of @tt{json-1.json} and @tt{json-2.json} are the same content, you will see either @tt{JSON files are equal} or @tt{JSON files are not equal}.

Equality of two JSON documents @tt{doc-1} and @tt{doc-2} is defined as follows: @tt{doc-1} and @tt{doc-2} have the same type (both are JSON objects, both are JSON strings, etc.) and adhere to the type-specific rules for equality, which are:

@itemlist[
  @item{two strings are equal is they are equal as Unicode strings (codepoint-for-codepoint equal sequences)}
  @item{two null values are equal if they are both null}
  @item{two number values are equal if they are mathematically equal representations of numbers in decimal notation}
  @item{two objects are equal if they have precisely the same keys (which are JSON strings) and, for each key, their corresponding values are equal, and}
  @item{two arrays are equal if they have the same length and if, for each  index, the value of the first array, at that index, is equal to the value at that index of the second array, at that index.}
]

@section[#:tag "equal-exit-code"]{Exit code}

@tt{equal} with arguments exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly two arguments, @tt{json-1.json} and @tt{json-2.json}, were supplied to it,}
  @item{@tt{json-1.json} exists and is a file,}
  @item{@tt{json-2.json} exists and is a file,}
  @item{@tt{json-1.json} is well-formed JSON, and}
  @item{@tt{json-2.json} is well-formed JSON.}
]

If any of these conditions fails, the exit code will be 1.

If the @tt{quiet} flag is used, the exit code will be 1 if the two inputs are represent different JSON documents. If the @tt{quiet} flag is not used, the exit code will always be 0 (provided, of course, that all of the above conditions are met).

@section{Options}

@tt{equal} accepts only one option, @tt{quiet}, which, if set, will cause all output to be suppressed. By default, this option is unset. In such a case, the exit code will be your only indication about the equality of your data.
