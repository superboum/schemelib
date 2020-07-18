(source-directories '("." ".."))
(include "crypto/core.scm")

; --- BROADCAST ENCRYPTION
; http://cryptowiki.net/index.php?title=Broadcast_encryption

(define be-envelope-length 
  (+ 
    crypto_secretbox_KEYBYTES
    crypto_box_SEALBYTES))

(define (be-add-envelope port pk-list key)
 (let f ([pk-iter pk-list])
   (let ([ret (crypto-box-seal key (car pk-iter))])
     (cond
       ((not ret) #f)
       (#t
         (put-bytevector port ret)
         (cond ((null? (cdr pk-iter)) #t) (#t (f (cdr pk-iter)))))))))

(define (be-add-content port key msg)
  (let ([cipher (crypto-extra-secretbox key msg)])
    (cond
      ((not cipher) #f)
      (#t (put-bytevector port cipher) #t))))
       
(define (be-encrypt pk-list key msg)
  (let-values [((port gen) (open-bytevector-output-port))]
    (cond
      ((not (be-add-envelope port pk-list key)) (close-port port) #f)
      ((not (be-add-content port key msg)) (close-port port) #f)
      (#t
        (let ([res (gen)]) (close-port port) res)))))

(define (be-decrypt pk sk cipher)
  (let ([envelope (make-bytevector be-envelope-length)]
        [max-envelopes (floor (/ (bytevector-length cipher) be-envelope-length))])
    (let f ([i 0])
      (cond
        ((>= i max-envelopes) #f)
        (#t 
          (bytevector-copy! cipher (* i be-envelope-length) envelope 0 be-envelope-length)
          (let ([key (crypto-box-seal-open envelope pk sk)])
            (cond
              ((not key) (f (+ i 1)))
              (#t
                (let* ([secrboxstart (* (+ i 1) be-envelope-length)]
                       [secrbox (make-bytevector (- (bytevector-length cipher) secrboxstart))])
                  (bytevector-copy! cipher secrboxstart secrbox 0 (bytevector-length secrbox))
                  (values key (crypto-extra-secretbox-open key secrbox))
)))))))))

