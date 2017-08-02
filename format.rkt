#lang racket/base

(module+ test
  (require rackunit))

(require (only-in racket/match
                  match-let))

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
           (error "Unexpected result from regexp-match:" m)))))

(module+ test
  (check-true (date-time? "1985-04-12T23:20:50.52Z"))
  (check-true (date-time? "1996-12-19T16:39:57-08:00"))
  (check-true (date-time? "1990-12-31T23:59:60Z"))
  (check-true (date-time? "1990-12-31T15:59:60-08:00"))
  (check-true (date-time? "1937-01-01T12:00:27.87+00:20"))
  (check-false (date-time? "1937-02-29T12:00:27.87+00:20"))
  (check-false (date-time? "1937-02-28T24:00:27.87+00:20"))
  (check-false (date-time? "1990-12-31T23:59:60Z"))
  (check-false (date-time? "1990-13-31T23:59:60Z"))
  (check-false (date-time? "1990-01-32T23:59:60Z"))
  (check-false (date-time? "2016-02-30T23:59:60Z"))
  (check-true (date-time? "2016-02-29T23:59:60Z")))

(provide date-time?)

;; https://tools.ietf.org/html/rfc5322#section-3.4.1
(define (email? x)
  #t)

(provide email?)

;; https://tools.ietf.org/html/rfc1034#section-3.1
(define (hostname? x)
  #t)

(provide hostname?)

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
