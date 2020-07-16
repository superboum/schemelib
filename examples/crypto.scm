(source-directories '("." ".."))
(include "bindings/utils.scm")
(include "bindings/sodium.scm")

(define-ftype [key (array 32 unsigned-8)])

(check-err (sodium_init))
(alloc 32 (lambda (ptr)
  (printf "~a ~%" (ftype-pointer->sexpr (make-ftype-pointer key ptr)))
  (randombytes_buf ptr 32)
  (printf "~a ~%" (ftype-pointer->sexpr (make-ftype-pointer key ptr)))
))
