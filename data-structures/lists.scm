(define (nth li pos)
  (cond
    ((null? li) #f)
    ((= pos 0) (car li))
    (#t (nth (cdr li) (- pos 1)))))

(define (rangeinc b e)
  (cond
    ((> b e) '())
    (#t (cons b (rangeinc (+ 1 b) e)))))

(define (less-than l n) 
  (cond 
    ((null? l) #t) 
    ((<= n 0) #f) 
    (#t (less-than (cdr l) (- n 1)))))

(define (sub l n)
  (cond
    ((null? l) '())
    ((<= n 0) '())
    (#t (cons (car l) (sub (cdr l) (- n 1))))))

(define (ltrim li beg end)
  (cond
    ((> beg 0) (ltrim (cdr li) (- beg 1) end))
    (#t (sub li (- (length li) end)))))

(define (slidewin l n)
  (append
    (let s ([m 1])
      (cond
        ((>= m n) '())
        (#t (cons (sub l m) (s (+ m 1))))))

    (let r ([iter l])
      (cond
        ((null? iter) '())
        (#t (cons (sub iter n) (r (cdr iter))))))))



(define (for fx times)
  (cond
    ((<= times 0) '())
    (#t (cons (fx) (for fx (- times 1))))))

(define (beginning l n)
  (cond
    ((null? l) '())
    ((<= n 0) '())
    (#t (cons (car l) (beginning (cdr l) (- n 1))))))

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

(define (zip l1 l2)
  (cond
    ((or (null? l1) (null? l2)) '())
    (#t (cons `(,(car l1) . ,(car l2)) (zip (cdr l1) (cdr l2))))))
