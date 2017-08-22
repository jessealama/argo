#lang scribble/manual

@title{Shortcomings and sorely missing features}

* Hypermedia keywords (base, links, media) are currently not supported. When these properties are encountered on a JSON schema, they are silently ignored. If you work with JSON schema that rely on these features, it will almost certainly not work with Argo. (Meanining: validation will produce many false negatives and maybe even some false positives.)
* Error reporting is missing. If a JSON document is not valid according to a JSON schema, you just get #f. You don't get a description of *why* the document fails validation.
* As of writing, the current version of the JSON Schema specification is 6. Earlier versions of JSON Schema are not supported. Schema that declare themselves to be, say, a v4 JSON Schema may not be treated correctly (that is, according to the v4 rules). If you can, either leave out the $schema keyword or use the value "http://json-schema.org/draft-06/schema#" for $schema.
