(library (schemelib bindings libc helpers)
  (export orflag->int)
  (import (chezscheme))

  (define (orflag->int flag-bind)
    (lambda (flag)
      (let ([lflag (cond ((list? flag) flag) (#t (list flag)))])
        (let f ([flag-iter lflag])
          (cond
            ((null? flag-iter) 0)
            (#t
              (bitwise-ior (cdr (assoc (car flag-iter) flag-bind)) (f (cdr flag-iter)))))))))
)
