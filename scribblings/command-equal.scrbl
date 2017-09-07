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

See the documentation for @racket[json-equal?] to see the definition of what it means for two JSON documents to be equal.

@bold{Exit code}

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

@bold{Options}

@tt{equal} accepts only one option, @tt{quiet}, which, if set, will cause all output to be suppressed. By default, this option is unset. In such a case, the exit code will be your only indication about the equality of your data.
