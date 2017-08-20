#lang racket/base

(require (only-in racket/match
                  match-let))

(module+ test
  (require rackunit))

(define (at-most-255? x)
  (and (string? x)
       (or (regexp-match-exact? #rx"[0-9]" x)
           (regexp-match-exact? #rx"[1-9][0-9]" x)
           (regexp-match-exact? #rx"[1][0-9][0-9]" x)
           (regexp-match-exact? #rx"[2][0-4][0-9]" x)
           (regexp-match-exact? #rx"[2][5][0-5]" x))))

(module+ test
  (check-false (at-most-255? 254))
  (check-false (at-most-255? "joe"))
  (check-false (at-most-255? "-1"))
  (check-true (at-most-255? "7"))
  (check-true (at-most-255? "0"))
  (check-true (at-most-255? "19"))
  (check-true (at-most-255? "198"))
  (check-true (at-most-255? "240"))
  (check-true (at-most-255? "255"))
  (check-false (at-most-255? "256"))
  (check-false (at-most-255? "523"))
  (check-false (at-most-255? "2555")))

(define (ipv4? x)
  (and (string? x)
       (let ([m (regexp-match #px"^([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})[.]([0-9]{1,3})$" x)])
         (cond ((not (list? m))
                #f)
               (else
                (match-let ([(list whole part-1 part-2 part-3 part-4) m])
                  (and (at-most-255? part-1)
                       (at-most-255? part-2)
                       (at-most-255? part-3)
                       (at-most-255? part-4))))))))

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
