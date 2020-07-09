(load "../bindings/libc.scm")

(define (check-err ret msg)
  (cond
    ((< ret 0)
     (perror msg)
     (raise msg))
    (#t ret)))

(define (udpsock-create fx)
  (fx 
    (check-err 
      (socket 'AF_INET 'SOCK_DGRAM 'IPPROTO_IP)
      "Unable to init UDP socket")))

(define (udpsock-reuseaddr sock)
  (alloc 
    (ftype-sizeof int)
    (lambda (activation)
      (foreign-set! 'int activation 0 1)
      (check-err
        (setsockopt 
          sock
          'SOL_SOCKET 
          'SO_REUSEADDR
          activation
          (ftype-sizeof int))
        "Unable to set REUSE ADDRESS"))))

(udpsock-create
  (lambda (s)
    (udpsock-reuseaddr s)
    (printf "~a~%" s)))
