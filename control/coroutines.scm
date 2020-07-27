(define coroutines '())
(define locked (make-eq-hashtable))
(define co-done "coroutines were no started correctly")

; private API
(define (co-add t) 
   (set! coroutines (append coroutines (list t))))

(define (co-start)
  (cond
    ((null? coroutines) (co-done))
    (#t
      (let ([c (car coroutines)])
        (set! coroutines (cdr coroutines))
        (c)))))

; public api
(define (co)
  (call/cc
    (lambda (k) 
      (set! co-done (lambda () (k #f)))
      (co-start))))

(define (co-thunk f)
  (co-add (lambda () (f) (co-end))))

(define (co-lock lname)
  (call/cc
    (lambda (k)
      (hashtable-set! locked lname (lambda () (k #f)))
      (co-start)
)))

(define (co-unlock lname)
  (let ([f (hashtable-ref locked lname #f)])
    (cond (f 
        (co-add f)
        (hashtable-delete! locked lname)))))

(define (co-end) 
  (call/cc 
    (lambda (k) (co-start))))

(define (co-pause)
  (call/cc
    (lambda (k)
      (co-add (lambda () (k #f)))
      (co-start))))


