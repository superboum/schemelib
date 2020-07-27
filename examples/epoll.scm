(source-directories '("." "./schemelib"))
(include "schemelib.scm")

; tests
(define (test-epoll)
  (epoll-env (lambda (epfd ev events max-events)
    (let ([sl (nb-listen "127.0.0.1" 3500)])
      (epoll-add epfd sl '(EPOLLIN EPOLLET) ev)

      (let f ()
        (for-each
          (lambda (evt)
            (cond
              ((= sl (car evt)) 
                (let ([client (nb-accept sl)])
                  (epoll-add epfd (car client) '(EPOLLIN EPOLLET) ev)
                  (printf "added ~a ~%" client)))
              ((= (epoll-ev->int 'EPOLLIN) (cdr evt))
                (let ([bv (make-bytevector 32)])
                  (recv (car evt) bv 32 'MSG_DEFAULT)
                  (printf "read: ~a~%" (utf8->string bv))))
              (#t
                (printf "oups~%"))))
          (epoll-wait epfd events max-events -1))
        (f))
))))

