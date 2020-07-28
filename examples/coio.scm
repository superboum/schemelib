(source-directories '("." ".."))
(include "schemelib.scm")

(define (test-coio)
(coio-event-loop "192.168.1.103")
(co-thunk (lambda ()
  (coio-connect '((host . "192.168.1.102")))
  ;(coio-send '((host . "127.0.0.1")) #vu8(45 110 89 111))
  ;(coio-send '((host . "127.0.0.1")) #vu8(2 0 0 0))
))

(co-thunk (lambda ()
  (let f ()
    (printf "recv: ~a~%" (values->list coio-recv))
    (f))
))

(co)
)
