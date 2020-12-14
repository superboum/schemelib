(source-directories '("." "../.."))
(import
  (schemelib bindings libc epoll)
  (schemelib bindings libc network)
  (schemelib bindings libc fd))

; tests
(define (test-epoll)
  (let-values ([(epfd ev events max-events) (epoll-init)])
    (let ([sl (nb-listen "127.0.0.1" 3500)])
      (epoll-add epfd sl '(EPOLLIN EPOLLET) ev)

      (let f ()
        (for-each
          (lambda (evt)
            (printf "evt: ~a~%" evt)
            (cond
              ((epoll-evt? evt 'EPOLLRDHUP)
                (printf "hup~%"))
              ((= sl (car evt)) 
                (let ([client (nb-accept sl)])
                  (epoll-add epfd (car client) '(EPOLLRDHUP EPOLLIN EPOLLET) ev)
                  (printf "added ~a ~%" client)))
              ((epoll-evt? evt 'EPOLLIN)
                (let ([bv (make-bytevector 32)])
                  (recv (car evt) bv 32 'MSG_DEFAULT)
                  (printf "read: ~a~%" (utf8->string bv))
                  (send (car evt) (string->utf8 "ok\n") 3 'MSG_DEFAULT)))
              (#t
                (printf "oups~%"))))
          (epoll-wait epfd events max-events -1))
        (f))

      (epoll-free epfd ev events max-events)
)))

