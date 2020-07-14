(source-directories '("." ".."))
(include "io/udpsock.scm")
(include "bindings/utils.scm")

(udpsock-create
  (lambda (sock)
    (udpsock-reuseaddr sock)
    (udpsock-bind sock "127.0.0.8" 1337)
    (udpsock-io 
      sock 
      (lambda (host port buf nread send)
        (let* ([charbuf (make-ftype-pointer char buf)]
              [udpmsg (char*->string charbuf nread)])
          (printf 
            "host: ~a, port: ~a, nread: ~a, buf: ~a~%"
            host port nread udpmsg)
          (send host port (ftype-pointer-address (string->char* udpmsg charbuf nread)) nread)
)))))
