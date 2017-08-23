#lang scribble/manual

@title{Shortcomings and sorely missing features}

Argo suffers from the some known deficiencies.

@section{Hypermedia keywords unsupported}

JSON Schema defines Hypermedia keywords (base, links, media) are currently not supported. When these properties are encountered on a JSON schema, they are silently ignored. If you work with JSON schema that rely on these features, it will almost certainly not work with Argo. (Meanining: validation will produce many false negatives and maybe even some false positives.)

@section{Error reporting}

Error reporting is largely (or should I say, entirely) missing. Thus, if a JSON document is not valid according to a JSON schema, you just get @racket[#f]. You don't get a description of @italic{why} the document fails validation.

@section{Only version 6 of the JSON Schema specification is supported}

Only verson 6 of the JSON Schema specification is supported. Schema that declare themselves to be, say, a v4 JSON Schema may not be treated correctly (that is, according to the v4 rules). If you can, either leave out the $schema keyword or use the value "http://json-schema.org/draft-06/schema#" for $schema.
