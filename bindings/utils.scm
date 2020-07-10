; Convert a char* to a Scheme string
; Extracted from this paper:
; http://scheme2011.ucombinator.org/papers/Keep2011.pdf
(define (char*->string fptr maxsize)
  (let f ([i 0])
    (let ([c (ftype-ref char () fptr i)])
      (if (or (char=? c #\nul) (and (> maxsize 0) (>= i maxsize)))
          (make-string i)
          (let ([str (f (fx+ i 1))])
            (string-set! str i c) str)))))

(define (string->char* src dest destmax)
  (let ([strlen (string-length src)])
    (let f ([i 0])
      (cond
        ((or (>= i strlen) (>= i destmax)) dest)
        (#t 
          (ftype-set! char () dest i (string-ref src i))
          (f (fx+ i 1)))))))

(define (alloc size fx)
  (let ([v (foreign-alloc size)])
    (fx v)
    (foreign-free v)))

(define (check-err ret msg)
  (cond
    ((< ret 0)
     (perror msg)
     (raise msg))
    (#t ret)))
