(source-directories '("." ".."))
(include "schemelib.scm")

(define (test-coio src dest)
  (co-thunk (lambda ()
    (coio-connect `((host . ,dest)))
    (coio-send `((host . ,dest)) (make-bytevector 15 7))
    (coio-send `((host . ,dest)) #vu8(2 0 0 0))
  ))

  (co-thunk (lambda ()
    (let f ()
      (printf "recv: ~a~%" (values->list coio-recv))
      (f))
  ))

  (co-thunk (lambda ()
    (let f ()
      (printf "connectrdy: ~a~%" (coio-ready))
      (f))))

  (coio-event-loop src)
  (co)
)
