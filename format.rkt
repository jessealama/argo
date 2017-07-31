#lang racket/base

(module+ test
  (require rackunit))

;; format validation:
;;
;; * date-time
;; * email
;; * hostname
;; * ipv4
;; * ipv6
;; * uri
;; * uri-reference
;; * uri-template
;; * json-pointer

(define (date-time? x)
  #t)

(provide date-time?)

(define (email? x)
  #t)

(provide email?)

(define (hostname? x)
  #t)

(provide hostname)

(define (ipv4? x)
  #t)

(provide ipv4?)

(define (ipv6? x)
  #t)

(provide ipv6?)

(define (uri? x)
  #t)

(provide uri?)

(define (uri-reference? x)
  #t)

(provide uri-reference?)

(define (uri-template? x)
  #t)

(provide uri-template?)

(define (json-pointer? x)
  #t)

(provide json-pointer?)
