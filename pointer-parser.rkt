#lang brag
json-pointer : ("/" reference-token)*
reference-token : escaped | NO-SLASH-NO-TILDE
escaped : "~0" | "~1"
