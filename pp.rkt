#lang racket/base

(require (only-in (file "./json.rkt")
                  count-properties
                  object-properties
                  property-value))

(require ejs)

(require (only-in racket/port
                  with-output-to-string))

(require (only-in racket/list
                  take
                  last
                  rest
                  first
                  empty?))

(require (only-in racket/string
                  string-split
                  string-trim))

(module+ test
  (require rackunit))

(define spaces-per-indentation-level 2)

(define (make-pad indentation-level)
  (make-string (* indentation-level spaces-per-indentation-level)
               #\space))

(define (indent-line str indentation)
  (format "~a~a" (make-pad indentation) str))

(define (indent-lines/list lines indentation)
  (cond ((empty? lines)
         (make-pad indentation))
        ((empty? (rest lines))
         (indent-line (first lines) indentation))
        (else
         (format "~a~%~a"
                 (indent-line (first lines) indentation)
                 (indent-lines/list (rest lines) indentation)))))

(module+ test
  (check-equal? "" (indent-lines/list (list) 0))
  (check-equal? "a" (indent-lines/list (list "a") 0))
  (check-equal? "  a" (indent-lines/list (list "a") 1))
  (check-equal? "hi\nthere" (indent-lines/list (list "hi" "there") 0))
  (check-equal? "    ahlan\n    thabatat" (indent-lines/list (list "ahlan" "thabatat") 2)))

(define (explode-lines str)
  (string-split str "\n"))

(define (indent-lines/str str indentation)
  (indent-lines/list (explode-lines str)
                     indentation))

(define (json-pretty-print js)
  (unless (ejsexpr? js)
    (error "Not a jsepr? value."))
  (define (pp x level)
    (define (indent str)
      (indent-lines/str str level))
    (let ([pad (make-pad level)])
      (cond ((ejs-null? x)
             "null")
            ((ejs-number? x)
             (format "~a" x))
            ((ejs-boolean? x)
             (if x "true" "false"))
            ((ejs-string? x)
             (format "~s" x))
            ((ejs-array? x)
             (let ([num-items (length x)]
                   [items x])
               (if (= num-items 0)
                   "[]"
                   (with-output-to-string
                     (lambda ()
                       (display "[")
                       (newline)

                       ;; all elements except the final one
                       (for ([item (take items (- num-items 1))])
                         (display (indent-lines/str (pp item 0) 1))
                         (display ",")
                         (newline))

                       ;; last item
                       (display (indent-lines/str (pp (last items) 0) 1))
                       (newline)
                       (display "]"))))))
            ((ejs-object? x)
             (let ([num-props (count-properties x)])
               (if (= num-props 0)
                   "{}"
                   (with-output-to-string
                     (lambda ()
                       (display "{")
                       (newline)
                       (let ([pad (make-pad (+ level 1))]
                             [props (object-properties x)])

                         ;; all but final property
                         (for ([prop (take props (- num-props 1))])
                           (display (indent-line (format "\"~s\": " prop)
                                                 1))
                           (display (string-trim (indent-lines/str (pp (property-value x prop) 0) 1)
                                                 " "
                                                 #:left? #t
                                                 #:right? #f
                                                 #:repeat? #t))
                           (display ",")
                           (newline))
                         (let ([final (last props)])
                           (display (indent-line (format "\"~s\": " final)
                                                 1))
                           (display (string-trim (indent-lines/str (pp (property-value x final) 0) 1)
                                                 " "
                                                 #:left? #t
                                                 #:right? #f
                                                 #:repeat? #t))))
                       (newline)
                       (display "}"))))))
            (else
             (error "Unhandled JSON data:" x)))))
  (pp js 0))

(provide json-pretty-print)

(module+ test
  (check-equal? (json-pretty-print 'null)
                "null")
  (check-equal? (json-pretty-print -5)
                "-5")
  (check-equal? (json-pretty-print "hello!")
                "\"hello!\"")
  (check-equal? (json-pretty-print #f)
                "false")
  (check-equal? (json-pretty-print (list))
                "[]")
  (check-equal? (json-pretty-print (make-string 1 #\nul))
                "\"\\u0000\"")
  (check-equal? (json-pretty-print "üff då phô")
                "\"üff då phô\"")
  (check-equal? (json-pretty-print (hasheq))
                "{}")
  (check-equal? (json-pretty-print (list #t "jim bob" (list)))
"[
  true,
  \"jim bob\",
  []
]")
  (let ([obj (hasheq 'some "pig" 'pig 'null)])
    (let ([rendered (json-pretty-print obj)])
      (check-true (or (string=? rendered "{\n  \"some\": \"pig\",\n  \"pig\": null\n}")
                      (string=? rendered "{\n  \"pig\": null,\n  \"some\": \"pig\"\n}")) rendered)))
  (let ([doc (hasheq 'dependencies (hasheq 'foo (list "bar")))])
    (check-equal? (json-pretty-print doc)
                   "{\n  \"dependencies\": {\n    \"foo\": [\n      \"bar\"\n    ]\n  }\n}"))
  (check-equal? (json-pretty-print (list 5 (list #t) 'null))
                "[\n  5,\n  [\n    true\n  ],\n  null\n]"))
