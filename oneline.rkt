#lang racket/base

(require (only-in json
                  jsexpr?))

(require (only-in (file "json.rkt")
                  json-null?
                  json-number?
                  json-boolean?
                  json-string?
                  json-array?
                  json-object?
                  array-length
                  array-items
                  count-properties
                  object-properties
                  property-value))

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

(define (json-in-one-line js)
  (unless (jsexpr? js)
    (error "Not a jsepr? value."))
  (cond ((json-null? js)
         "null")
        ((json-number? js)
         (format "~a" js))
        ((json-boolean? js)
         (if js "true" "false"))
        ((json-string? js)
         (format "~s" js))
        ((json-array? js)
         (let ([num-items (array-length js)]
               [items (array-items js)])
           (if (= num-items 0)
               "[]"
               (with-output-to-string
                 (lambda ()
                   (display "[")

                   ;; all elements except the final one
                   (for ([item (take items (- num-items 1))])
                     (display (json-in-one-line item))
                     (display ","))

                   ;; last item
                   (display (json-in-one-line (last items)))
                   (display "]"))))))
            ((json-object? js)
             (let ([num-props (count-properties js)])
               (if (= num-props 0)
                   "{}"
                   (with-output-to-string
                     (lambda ()
                       (display "{")
                       (let ([props (object-properties js)])

                         ;; all but final property
                         (for ([prop (take props (- num-props 1))])
                           (display (format "\"~s\":" prop))
                           (display (json-in-one-line (property-value js prop)))
                           (display ","))
                         (let ([final (last props)])
                           (display (format "\"~s\":" final))
                           (display (json-in-one-line (property-value js final)))))
                       (display "}"))))))
            (else
             (error "Unhandled JSON data:" js))))

(provide json-in-one-line)

(module+ test
  (check-equal? (json-in-one-line 'null)
                "null")
  (check-equal? (json-in-one-line -5)
                "-5")
  (check-equal? (json-in-one-line "hello!")
                "\"hello!\"")
  (check-equal? (json-in-one-line #f)
                "false")
  (check-equal? (json-in-one-line (list))
                "[]")
  (check-equal? (json-in-one-line (make-string 1 #\nul))
                "\"\\u0000\"")
  (check-equal? (json-in-one-line "üff då phô")
                "\"üff då phô\"")
  (check-equal? (json-in-one-line (hasheq))
                "{}")
  (check-equal? (json-in-one-line (list #t "jim bob" (list)))
                "[true,\"jim bob\",[]]")
  (let ([obj (hasheq 'some "pig" 'pig 'null)])
    (let ([rendered (json-in-one-line obj)])
      (check-true (or (string=? rendered "{\"some\":\"pig\",\"pig\":null}")
                      (string=? rendered "{\"pig\":null,\"some\":\"pig\"}")) rendered)))
  (let ([doc (hasheq 'dependencies (hasheq 'foo (list "bar")))])
    (check-equal? (json-in-one-line doc)
                   "{\"dependencies\":{\"foo\":[\"bar\"]}}"))
  (check-equal? (json-in-one-line (list 5 (list #t) 'null))
                "[5,[true],null]"))