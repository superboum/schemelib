(define (rangeinc b e)
  (cond
    ((> b e) '())
    (#t (cons b (rangeinc (+ 1 b) e)))))

(define (less-than l n) (cond ((null? l) #t) ((<= n 0) #f) (#t (less-than (cdr l) (- n 1)))))
(define (unit v) v)
(define (aget key alist) (cdr (assoc key alist)))
(define (aset key val alist)
  (cond
    ((null? alist) `((,key . ,val)))
    ((eqv? (caar alist) key) (cons `(,key . ,val) (cdr alist))) ; found and updated
    (#t (cons (car alist) (aset key val (cdr alist))))    ; continue to seek
))

(define (dedup l p c) 
  (cond 
    ((null? l) `(((str . ,p) (ctr . ,c)))) 
    ((string=? p (car l)) (dedup (cdr l) p (+ c 1)))
    (#t (cons `((str . ,p) (ctr . ,c)) (dedup (cdr l) (car l) 1)))
))

(define (dedup<=? d1 d2)
  (<= (aget 'ctr d1) (aget 'ctr d2)))


