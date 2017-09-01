#lang racket/base

(require (only-in racket/match
                  match-let)
         (only-in racket/list
                  make-list
                  range))

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
  (check-false (ipv4? 127))
  (check-false (ipv4? #"127.0.0.1"))
  (check-false (ipv4? "000.000.000.000"))
  (check-false (ipv4? "310.142.873.9661"))
  (check-false (ipv4? "my.nfs.server")))

;; https://tools.ietf.org/html/rfc2373#section-2.2
(define (ipv6? x)
  (define (type-1? x)
    (regexp-match-exact? #px"[[:xdigit:]]{1,4}([:][[:xdigit:]]{1,4}){7}" x))
  (define (type-2/complete? x)
    (string=? x "::"))
  (define (type-2/begin? x)
    (and (regexp-match? #rx"^::" x) ;; starts with "::"
         (let ([r (substring x 2)])
           (ormap (lambda (n)
                    ;; substitue "::" with n copies of "0:"
                    (let* ([appended (apply string-append (make-list n "0:"))]
                           [expanded (format "~a~a" appended r)])
                      (or (type-1? expanded)
                          (type-3? expanded))))
                  (range 1 8)))))
  (define (type-2/end? x)
    (and (regexp-match? #rx"::$" x) ;; ends with "::"
         (let ([r (substring x 0 (- (string-length x) 2))])
           (ormap (lambda (n)
                    ;; substitue "::" with n copies of ":0"
                    (let* ([appended (apply string-append (make-list n ":0"))]
                           [expanded (format "~a~a" appended r)])
                      (or (type-1? expanded)
                          (type-3? expanded))))
                  (range 1 8)))))
  (define (type-2/middle? x)
    (let ([m (regexp-match #rx"^(.+)::(.+)$" x)])
      (and (list? m)
           (let ([before (list-ref m 1)]
                 [after (list-ref m 2)])
             ;; (log-error "before = \"~a\"" before)
             ;; (log-error "after = \"~a\"" after)
             (ormap (lambda (n)
                      ;; substitue "::" with n copies of "0:"
                      (let* ([appended (apply string-append (make-list n "0:"))]
                             [expanded (format "~a:~a~a" before appended after)])
                        ;; (log-error (format "trying \"~a\"" expanded))
                        (or (type-1? expanded)
                            (type-3? expanded))))
                    (range 1 7))))))
  (define (type-2? x)
    (or (type-2/complete? x)
        (type-2/begin? x)
        (type-2/end? x)
        (type-2/middle? x)))
  (define (type-3? x)
    (let ([m (regexp-match #px"^[[:xdigit:]]{1,4}([:][[:xdigit:]]{1,4}){5}[:](.+)$" x)])
      (and (list? m)
           (ipv4? (list-ref m 2)))))
  (and (string? x)
       (not (regexp-match? "[^0-9a-fA-F:.]" x))
       (or (type-1? x)
           (type-2? x)
           (type-3? x))))

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
  (check-true (ipv6? "FF01:0:0:0:0:0:0:101"))

  ;; type 2
  (check-true (ipv6? "1080::8:800:200C:417A"))
  (check-true (ipv6? "FF01::101"))
  (check-true (ipv6? "::1"))
  (check-false (ipv6? "::1::"))
  (check-true (ipv6? "::"))
  (check-false (ipv6? ":::"))
  (check-false (ipv6? ":::1"))
  (check-true (ipv6? "1080::8:800:200C:417A"))
  (check-false (ipv6? "1080::91FF:54AB:8:800:200C:417A:0094"))

  ;; type 3
  (check-true (ipv6? "0:0:0:0:0:0:13.1.68.3"))
  (check-true (ipv6? "0:0:0:0:0:FFFF:129.144.52.38"))
  (check-true (ipv6? "::13.1.68.3"))
  (check-true (ipv6? "::FFFF:129.144.52.38")))
