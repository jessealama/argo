#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Further reading}

To learn more about JSON Schema, go to the source: @url{http://json-schema.org}. The specificiations that Argo aims to follow are in two documents:

@itemlist[
  @item{@hyperlink[#:underline? #f "http://json-schema.org/latest/json-schema-core.html"]{JSON Schema Core}}
  @item{@hyperlink[#:underline? #f "http://json-schema.org/latest/json-schema-validation.html"]{JSON Schema Validation}}
]

(The third part of the JSON Schema specification that is currently @italic{not} implemented by Argo is @hyperlink[#:underline? #f "http://json-schema.org/latest/json-schema-hypermedia.html"]{JSON Hyper-Schema}.)

Finally, you're welcome to visit @hyperlink[#:underline? #f "http://argojson.com"]{the Argo homepage} to read about updates and other JSON Schema goodies.
