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
      (socket 'AF_INET 'SOCK_DGRAM 'IPPROTO_NONE)
      "Unable to init UDP socket")))

(udp-sock 
  (lambda (s)
    (printf "~a~%" s)))
