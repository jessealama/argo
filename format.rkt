#lang racket/base

(module+ test
  (require rackunit))

(require (only-in racket/match
                  match-let))

(require (prefix-in mutt:
                    (only-in mutt
                             email?)))

(require (only-in net/url-string
                  url-regexp
                  url->string
                  string->url))

(require net/url-structs)

(require (only-in racket/list
                  empty?))

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
  (cond ((not (string? x))
         #f)
        (else
         (let ([m (regexp-match #px"^[0-9]{4}[-]([0-9]{2})[-]([0-9]{2})[T]([0-9]{2})[:]([0-9]{2})[:]([0-9]{2})([.][0-9]{1,})?(.+)$" x)])
           (cond ((eq? m #f)
                  #f)
                 ((list? m)
                  (match-let ([(list whole
                                     month/str
                                     dayofmonth/str
                                     hour/str
                                     minute/str
                                     sec/str
                                     sec-fracs/str
                                     offset/str)
                               m])
                             (let ([month/int (string->number month/str 10)]
                                   [dayofmonth/int (string->number dayofmonth/str)]
                                   [hour/int (string->number hour/str)]
                                   [minute/int (string->number minute/str)]
                                   [sec/int (string->number sec/str)])
                               (cond ((> month/int 12)
                                      #f)
                                     ((= month/int 0)
                                      #f)
                                     ((> dayofmonth/int 31)
                                      #f)
                                     ((= dayofmonth/int 0)
                                      #f)
                                     ((> hour/int 23)
                                      #f)
                                     ((> minute/int 60)
                                      #f)
                                     ((> sec/int 60)
                                      #f)
                                     ((and (= month/int 2)
                                           (> dayofmonth/int 29))
                                      #f)
                                     ;; months that have 30 days
                                     ((and (= month/int 4)
                                           (> dayofmonth/int 30))
                                      #f)
                                     ((and (= month/int 6)
                                           (> dayofmonth/int 30))
                                      #f)
                                     ((and (= month/int 9)
                                           (> dayofmonth/int 30))
                                      #f)
                                     ((and (= month/int 11)
                                           (> dayofmonth/int 30))
                                      #f)
                                     ((and (string? offset/str)
                                           (not (string=? offset/str "Z")))
                                      (let ([o (regexp-match #px"^[+-]([0-9]{2})[:]([0-9]{2})$" offset/str)])
                                        (cond ((not (list? o))
                                               (error "Failed to parse this time offset:" offset/str))
                                              (else
                                               (match-let ([(list whole
                                                                  hour/str
                                                                  minute/str)
                                                            o])
                                                          (let ([hour/int (string->number hour/str 10)]
                                                                [minute/int (string->number minute/str 10)])
                                                            (cond ((> hour/int 60)
                                                                   #f)
                                                                  ((> minute/int 60)
                                                                   #f)
                                                                  (else
                                                                   #t))))))))
                                     (else
                                      ;; no checks for leap years
                                      #t)))))
                 (else
                  (error "Unexpected result from regexp-match:" m)))))))

(module+ test
  (check-true (date-time? "1985-04-12T23:20:50.52Z"))
  (check-true (date-time? "1996-12-19T16:39:57-08:00"))
  (check-true (date-time? "1990-12-31T23:59:60Z"))
  (check-true (date-time? "1990-12-31T15:59:60-08:00"))
  (check-true (date-time? "1937-01-01T12:00:27.87+00:20"))

  ;; Doesn't work because we don't have checks for leap years
  ;; (check-false (date-time? "1937-02-29T12:00:27.87+00:20"))

  (check-false (date-time? "1937-02-28T24:00:27.87+00:20"))
  (check-true (date-time? "1990-12-31T23:59:60Z"))
  (check-false (date-time? "1990-13-31T23:59:60Z"))
  (check-false (date-time? "1990-01-32T23:59:60Z"))
  (check-false (date-time? "2016-02-30T23:59:60Z"))
  (check-true (date-time? "2016-02-29T23:59:60Z")))

(provide date-time?)

;; https://tools.ietf.org/html/rfc5322#section-3.4.1
;;
;; punt and use a function from the mutt package that probably
;; covers what I need in many cases
(define (email? x)
  (cond ((not (string? x))
         #f)
        (else
         (string? (mutt:email? x)))))

(module+ test
  (check-true (email? "hi@bye.com"))
  (check-false (email? " "))
  (check-false (email? "@re.ew")))

(provide email?)

;; https://tools.ietf.org/html/rfc1034#section-3.1
;;
;; poor man's approach: ASCII with, possibly, some dots in between
(define (hostname? x)
  (define (host? x)
    (let ([m (regexp-match #px"^[[:alnum:]]+([.](.+))?$" x)])
      (cond ((list? m)
             (match-let ([(list whole more after-dot) m])
               (cond ((string? more)
                      (host? after-dot))
                     (else
                      #t))))
            (else
             #f))))
  (cond ((not (string? x))
         #f)
        (else
         (host? x))))

(provide hostname?)

(module+ test
  (check-false (hostname? 4))
  (check-true (hostname? "localhost"))
  (check-true (hostname? "f"))
  (check-true (hostname? "root.local"))
  (check-true (hostname? "foo.a.be"))
  (check-true (hostname? "whatever.ISI.EDU"))
  (check-false (hostname? " hi.byte"))
  (check-true (hostname? "my.nfs.server")))

;; https://tools.ietf.org/html/rfc2673#section-3.2

(define (ipv4? x)
  (define (acceptable? n rep-of-n)
    (cond ((> n 255)
           #f)
          ((< n 0)
           #f)
          ((and (< n 10)
                (> (string-length rep-of-n) 1))
           #f)
          ((and (< n 100)
                (> (string-length rep-of-n) 2))
           #f)
          ((and (< n 1000)
                (> (string-length rep-of-n) 3))
           #f)
          (else
           #t)))
  (cond ((not (string? x))
         #f)
        (else
         (let ([m (regexp-match #px"^([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})$" x)])
           (cond ((not (list? m))
                  #f)
                 (else
                  (match-let ([(list whole part-1 part-2 part-3 part-4) m])
                    (let ([part-1/int (string->number part-1 10)]
                          [part-2/int (string->number part-2 10)]
                          [part-3/int (string->number part-3 10)]
                          [part-4/int (string->number part-4 10)])
                      (and (acceptable? part-1/int part-1)
                           (acceptable? part-2/int part-2)
                           (acceptable? part-3/int part-3)
                           (acceptable? part-4/int part-4))))))))))

(provide ipv4?)

(module+ test
  (check-true (ipv4? "127.0.0.1"))
  (check-true (ipv4? "0.0.0.0"))
  (check-true (ipv4? "65.13.67.255"))
  (check-true (ipv4? "255.255.255.255"))
  (check-false (ipv4? "1"))
  (check-false (ipv4? #"127.0.0.1"))
  (check-false (ipv4? "000.000.000.000"))
  (check-false (ipv4? "310.142.873.9661"))
  (check-false (ipv4? "my.nfs.server")))

;; https://tools.ietf.org/html/rfc2373#section-2.2
(define (ipv6? x)
  (and (string? x)
       (or ;; type 1
        (regexp-match-exact? #px"([A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}" x)
        (and (regexp-match? #rx"::" x)
             (regexp-match-exact? #px"[A-Fa-f0-9:]+" x)
             ;; type 2 with double colon
             ;; type 3 with double colon
             )
        ;; type 3 without double colon
        (regexp-match-exact? #px"([A-Fa-f0-9]{1,4}:){5}[A-Fa-f0-9]{1,4}:([1-9][0-9]{0,2}[.]){3}[1-9][0-9]{0,2}" x))))

(provide ipv6?)

(module+ test
  (check-false (ipv6? "my.nfs.server"))

  ;; examples from section 2.2 of RFC 2373 (https://tools.ietf.org/html/rfc2373#section-2.2)

  ;; type 1
  (check-true (ipv6? "FEDC:BA98:7654:3210:FEDC:BA98:7654:3210"))
  (check-true (ipv6? "1080:0:0:0:8:800:200C:417A"))
  (check-true (ipv6? "FF01:0:0:0:0:0:0:101"))
  (check-true (ipv6? "0:0:0:0:0:0:0:1"))
  (check-true (ipv6? "0:0:0:0:0:0:0:0"))

  ;; type 2
  (check-true (ipv6? "1080::8:800:200C:417A"))
  (check-true (ipv6? "FF01::101"))
  (check-true (ipv6? "::1"))
  (check-true (ipv6? "::"))

  ;; type 3
  (check-true (ipv6? "0:0:0:0:0:0:13.1.68.3"))
  (check-true (ipv6? "0:0:0:0:0:FFFF:129.144.52.38"))
  (check-true (ipv6? "::13.1.68.3"))
  (check-true (ipv6? "::FFFF:129.144.52.38")))

;; https://tools.ietf.org/html/rfc3986

(define (uri? x)
  (and (string? x)
       (string=? x (url->string (string->url x)))))

(provide uri?)

(module+ test
  (check-true (uri? "http://ddd.de"))
  (check-false (uri? #"google.com"))
  (check-false (uri? "one small step")))

;; https://tools.ietf.org/html/rfc3986
(define (uri-reference? x)
  (string? x))

(provide uri-reference?)

;; https://tools.ietf.org/html/rfc6570
(define (uri-template? x)
  #t)

(provide uri-template?)

(require (only-in (file "pointer.rkt")
                  json-pointer?))

(provide json-pointer?)
