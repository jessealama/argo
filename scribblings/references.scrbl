#lang scribble/manual

@require[@for-label[racket/base
		    json]]

@title{Further reading}

To learn more about JSON Schema, go to the source:

@itemlist[
  @item{@url{http://json-schema.org}}
]

The specificiations that Argo aims to follow are in two documents:

@itemlist[
  @item{@hyperlink{JSON Schema Core}{http://json-schema.org/latest/json-schema-core.html}}
  @item{@hyperlink{JSON Schema Validation}{http://json-schema.org/latest/json-schema-validation.html}}
]

(The third part of the JSON Schema specification that is currently @italic{not} implemented by Argo is @hyperlink{JSON Hyper-Schema}{http://json-schema.org/latest/json-schema-hypermedia.html}.)
