(define coroutines '())
(define locked (make-eq-hashtable))
(define co-done "coroutines were no started correctly")
(define co-flush-saved #f)

; private API
(define (co-add t) 
   (set! coroutines (append coroutines (list t))))

(define (co-start)
  (cond
    ((and (null? coroutines) co-flush-saved)
      (let ([c co-flush-saved])
        (set! co-flush-saved #f) (c)))
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
      (hashtable-update! 
        locked 
        lname 
        (lambda (v) (cons (lambda () (k #f)) v))
        '())
      (co-start)
)))

(define (co-unlock lname)
  (let ([f (hashtable-ref locked lname '())])
    (cond 
      ((not (null? f)) 
        (co-add (car f))
        (cond
          ((null? (cdr f)) (hashtable-delete! locked lname))
          (#t (hashtable-set! locked lname (cdr f))))
))))

(define (co-end) 
  (call/cc 
    (lambda (k) (co-start))))

(define (co-flush) 
  (call/cc 
    (lambda (k) 
      (set! co-flush-saved (lambda () (k #f)))
      (co-start))))

(define (co-pause)
  (call/cc
    (lambda (k)
      (co-add (lambda () (k #f)))
      (co-start))))


