#lang racket/base

(define original-schema (make-parameter #f))

(provide original-schema)

(define current-id (make-parameter #f))

(provide current-id)
