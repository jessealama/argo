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

;; https://tools.ietf.org/html/rfc3339#section-5.6
(define (date-time? x)
  #t)

(module+ test
  (check-true (date-time? )))

(provide date-time?)

;; https://tools.ietf.org/html/rfc5322#section-3.4.1
(define (email? x)
  #t)

(provide email?)

;; https://tools.ietf.org/html/rfc1034#section-3.1
(define (hostname? x)
  #t)

(provide hostname)

;; https://tools.ietf.org/html/rfc2673#section-3.2
(define (ipv4? x)
  #t)

(provide ipv4?)

;; https://tools.ietf.org/html/rfc2373#section-2.2
(define (ipv6? x)
  #t)

(provide ipv6?)

;; https://tools.ietf.org/html/rfc3986
(define (uri? x)
  #t)

(provide uri?)

;; https://tools.ietf.org/html/rfc3986
(define (uri-reference? x)
  #t)

(provide uri-reference?)

;; https://tools.ietf.org/html/rfc6570
(define (uri-template? x)
  #t)

(provide uri-template?)

;; https://tools.ietf.org/html/rfc6901
(define (json-pointer? x)
  #t)

(provide json-pointer?)
