#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{schema}}

The @tt{schema} command takes a JSON file as input and checks that it is a schema. (Recall that ``schema'' for Argo is ``draft 06 schema''.)

Run it like this:

@verbatim{
raco argo schema schema.json
}

The output will tell you whether @tt{schema.json} really is a JSON Schema.

@section[#:tag "schema-exit-code"]{Exit code}

@tt{schema} exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly one argument, @tt{schema.json}, was supplied to it,}
  @item{@tt{schema.json} exists and is a file, and}
  @item{@tt{schema.json} is well-formed JSON.}
]

(Though see below for a way in which the exit code may be non-zero even if all these conditions are met.)

@section{Options}

@tt{schema} accepts only one option, @tt{quiet}, which, if set, will cause all output to be suppressed. By default, this option is unset. In such a case, the exit code will be your only indication about whether your JSON really is a schema.
