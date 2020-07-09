(load "../bindings/libc.scm")

(define (check-err ret msg)
  (cond
    ((< ret 0)
     (perror msg)
     (raise msg))
    (#t ret)))

(define (udp-sock fx)
  (fx 
    (check-err 
      (socket 'AF_INET 'SOCK_DGRAM 'IPPROTO_IP)
      "Unable to init UDP socket")))

(udp-sock 
  (lambda (s)
    (alloc 
      (ftype-sizeof int)
      (lambda (activation)
        (foreign-set! 'int activation 0 1)
        (check-err
          (setsockopt 
            s 
            'SOL_SOCKET 
            'SO_REUSEADDR
            activation
            (ftype-sizeof int))
          "Unable to set REUSE ADDRESS")))
    (printf "~a~%" s)))
