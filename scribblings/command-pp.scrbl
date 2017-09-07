#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{pp}}

The @tt{pp} command takes a JSON file as input and pretty prints it to the console.

Run it like this:

@verbatim{
raco argo pp data.json
}

@bold{Exit code}

@tt{pp} exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly one argument, @tt{data.json}, was supplied to it,}
  @item{@tt{data.json} exists and is a file, and}
  @item{@tt{data.json} is well-formed JSON.}
]

If any of these conditions fails, the exit code will be 1.

@bold{Options}

The command accepts no options.
