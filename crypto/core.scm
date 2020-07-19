; --- HIGH LEVEL API FOR SODIUM
(define (randombytes-buf size)
  (let [(v (make-bytevector size))]
    (randombytes_buf v size)
    v))

(define (crypto-box-seal msg pk)
  (let* ([mlen (bytevector-length msg)]
         [cipher (make-bytevector (+ mlen crypto_box_SEALBYTES))]
         [op (crypto_box_seal cipher msg mlen pk)])
    (cond ((not (= op 0)) #f) (#t cipher))))

(define (crypto-box-seal-open cipher pk sk)
  (let* ([clen (bytevector-length cipher)]
         [msg (make-bytevector (- clen crypto_box_SEALBYTES))]
         [op (crypto_box_seal_open msg cipher clen pk sk)])
    (cond ((not (= op 0)) #f) (#t msg))))

(define (crypto-secretbox-easy nonce msg key)
  (let* ([mlen (bytevector-length msg)]
         [cipher (make-bytevector (+ mlen crypto_secretbox_MACBYTES))]
         [op (crypto_secretbox_easy cipher msg mlen nonce key)])
    (cond ((not (= op 0)) #f) (#t cipher))))

(define (crypto-secretbox-open-easy nonce cipher key)
  (let* ([clen (bytevector-length cipher)]
         [msg (make-bytevector (- clen crypto_secretbox_MACBYTES))]
         [op (crypto_secretbox_open_easy msg cipher clen nonce key)])
    (cond ((not (= op 0)) #f) (#t msg))))

(define (crypto-box-keypair)
  (let ([pk (make-bytevector crypto_box_PUBLICKEYBYTES)]
        [sk (make-bytevector crypto_box_SECRETKEYBYTES)])
    (crypto_box_keypair pk sk)
    (values pk sk)))

; --- EXTRA BINDINGS FOR SODIUM
(define (crypto-extra-nonce-generator size)
  (let [(state (randombytes-buf size))]
    (lambda () 
      (let ([res (make-bytevector size)])
        (sodium_increment state size)
        (memcpy res state size)
        res))))

(define crypto-extra-secretbox-nonce (crypto-extra-nonce-generator crypto_secretbox_NONCEBYTES))

(define (crypto-extra-insert-nonce nonce cipher)
  (let*
    ([nlen (bytevector-length nonce)]
     [clen (bytevector-length cipher)]
     [r (make-bytevector (+ nlen clen))])

    (bytevector-copy! nonce 0 r 0 nlen)
    (bytevector-copy! cipher 0 r nlen clen)
    r))

(define (crypto-extra-extract-nonce cipher+nonce nlen)
  (let*
    ([flen (bytevector-length cipher+nonce)]
     [nonce (make-bytevector nlen)]
     [cipher (make-bytevector (- flen nlen))])

    (bytevector-copy! cipher+nonce 0 nonce 0 nlen)
    (bytevector-copy! cipher+nonce nlen cipher 0 (- flen nlen))
    (values nonce cipher)))

(define (crypto-extra-secretbox key msg)
  (let* ([nonce (crypto-extra-secretbox-nonce)]
         [cipher (crypto-secretbox-easy nonce msg key)])
    (cond
      ((not cipher) #f)
      (#t (crypto-extra-insert-nonce nonce cipher)))))

(define (crypto-extra-secretbox-open key cipher+nonce) 
  (let-values ([(nonce cipher) (crypto-extra-extract-nonce cipher+nonce crypto_secretbox_NONCEBYTES)])
    (crypto-secretbox-open-easy nonce cipher key)))
