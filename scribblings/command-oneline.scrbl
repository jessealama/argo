#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{oneline}}

The @tt{oneline} command takes a JSON file as input and renders it in a single line. It doesn't get more compressed than this.

@bold{Exit code}

The @tt{oneline} command exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly one argument, @tt{data.json}, was supplied to it,}
  @item{@tt{data.json} exists and is a file, and}
  @item{@tt{data.json} is well-formed JSON.}
]

If any of these conditions fails, the exit code will be 1.

@bold{Options}

@tt{oneline} accepts no options.
