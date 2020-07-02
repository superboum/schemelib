(define (marker-finder step not-found found port marker remaining)
  (let [(r (get-char port))]
    (cond
      ((eof-object? r) (not-found))
      ((char=? r (car remaining))
        (step 
          r 
          (cond
            ((null? (cdr remaining)) (found))
            (#t (marker-finder step not-found found port marker (cdr remaining))))))
      (#t (step r (marker-finder step not-found found port marker marker)))
)))

(define (read-until port marker)
  (list->string 
    (marker-finder
      (lambda (e r) (cons e r))
      (lambda () '())
      (lambda () '())
      port 
      (string->list marker) 
      (string->list marker)
)))

(define (seek-until port marker)
  (marker-finder
    (lambda (e r) r)
    (lambda () #f)
    (lambda () #t)
    port
    (string->list marker) 
    (string->list marker)
))

