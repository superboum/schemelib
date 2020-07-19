(source-directories '("." ".."))
(include "schemelib.scm")

(check-err (sodium_init))

(define (marshall v)
  (call-with-bytevector-output-port 
    (lambda (p) (fasl-write v p))))

(let ([content (marshall "hello world")]
      [key (randombytes-buf crypto_secretbox_KEYBYTES)])

  (printf "~a ~%" content)
  (printf "~a ~%" (crypto-extra-secretbox-open key (crypto-extra-secretbox key content))))
