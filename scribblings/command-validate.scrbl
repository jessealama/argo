#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{@tt{validate}}

The @tt{validate} command takes a JSON Schema file and a JSON file as input and checks that the data adheres to the schema.

Run it like this:

@verbatim{
raco argo validate schema.json data.json
}

You will see either @tt{Validation succeeded} or @tt{Validation failed}.

In case of validation success, seeing ``Validation succeeded'' is probably enough. In case of failure, ``Validation failed'' is, admittedly, not the most informative thing you've seen today. See also @secref{error-reporting}.

@bold{Exit code}

The @tt{validate} command exits cleanly (with code 0) provided:

@itemlist[
  @item{exactly two arguments, @tt{schema.json} and @tt{data.json}, were supplied to it,}
  @item{@tt{schema.json} exists and is a file,}
  @item{@tt{data.json} exists and is a file,}
  @item{@tt{schema.json} is well-formed JSON,}
  @item{@tt{data.json} is well-formed JSON,}
  @item{@tt{schema.json} is a (draft 6) JSON Schema, and}
  @item{@tt{data.json} adheres to @tt{schema.json} (following the draft 6 semantics).}
]

If any of these conditions fails, the exit code will be 1.

@bold{Options}

@tt{validate} accepts only one option, @tt{quiet}, which, if set, will cause all output to be suppressed. By default, this option is unset. In such a case, the exit code will be your only indication about the validity of your data. Here's how you can use this option:

@verbatim{
raco argo validate --quiet schema.json data.json
}

As discussed in the above concerning exit codes, there are seven conditions that need to be met for @tt{validate} to exit cleanly. Looking at that list there, another way to think of it is that there are six preconditions that need to be met for validation to even make sense. Even if the @tt{quiet} flag is set, you will see error output if any of these preconditions is not met. Thus

@verbatim{
raco argo validate --quiet schema.json
}

will cause an error message to be printed, despite the @tt{--quiet}, because this isn't even a well-formed invocation of @tt{validate} (notice that the second argument is missing).
