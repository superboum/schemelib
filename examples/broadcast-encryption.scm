(source-directories '("." ".."))
(include "schemelib.scm")

(define (marshall v)
  (call-with-bytevector-output-port 
    (lambda (p) (fasl-write v p))))

(let-values
   ([(pk1 sk1) (crypto-box-keypair)]
    [(pk2 sk2) (crypto-box-keypair)]
    [(key) (randombytes-buf crypto_secretbox_KEYBYTES)]
    [(content) (marshall "toto")])

  (printf "original message: ~a ~%" content)
  (let-values ([(key msg) (be-decrypt pk2 sk2 (be-encrypt (list pk1 pk2) key content))])
    (printf "cipher          : ~a ~%" msg)))
