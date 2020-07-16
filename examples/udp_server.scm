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
        (let ([tx (make-transcoder (utf-8-codec) (eol-style lf)
                  (error-handling-mode replace))]
              [content (make-bytevector nread)])
          (memcpy content buf nread)
          (printf 
            "host: ~a, port: ~a, nread: ~a, buf: ~a~%"
            host port nread (bytevector->string content tx))
          (send host port buf nread)
)))))
