(source-directories '("." ".."))
(include "schemelib.scm")

(define (test-coio)
(coio-event-loop "127.0.0.9")
(co-thunk (lambda ()
  (coio-connect '((host . "127.0.0.1")))
  (coio-send '((host . "127.0.0.1")) #vu8(45 110 89 111))
  (coio-send '((host . "127.0.0.1")) #vu8(2 0 0 0))
))

(co-thunk (lambda ()
  (let f ()
    (printf "recv: ~a~%" (values->list coio-recv))
    (f))
))

(co)
)
