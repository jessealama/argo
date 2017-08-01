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

;; All these functions assume that their argument is a string.

;; https://tools.ietf.org/html/rfc3339#section-5.6
(define (date-time? x)
  (regexp-match? #px"^[0-9]{4}[-][0-9]{2}[-][0-9]{2}[T][0-9]{2}[:][0-9]{2}[:][0-9]{2}([.][0-9]{1,})?(.+)$" x))

(module+ test
  (check-true (date-time? "1985-04-12T23:20:50.52Z"))
  (check-true (date-time? "1996-12-19T16:39:57-08:00"))
  (check-true (date-time? "1990-12-31T23:59:60Z"))
  (check-true (date-time? "1990-12-31T15:59:60-08:00"))
  (check-true (date-time? "1937-01-01T12:00:27.87+00:20")))

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
