(load "../bindings/libc.scm")

(define (check-err ret msg)
  (cond
    ((< ret 0)
     (perror msg)
     (raise msg))
    (#t ret)))

(define (alloc size fx)
  (let ([v (foreign-alloc size)])
    (fx v)
    (foreign-free v)))

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

(define (udpsock-bind sock addr port)
  (alloc 
    (ftype-sizeof sockaddr_in)
    (lambda (addr)
      (ftype-set! sockaddr_in (sin_family) addr (domain->int 'AF_INET))
      (ftype-set! sockaddr_in (sin_port) addr (htons port))
      (check-err
        (inet_pton 
          'AF_INET 
          addr 
          (ftype-&ref sockaddr_in (sin_addr) addr))
        "Unable to convert your IP address to binary")
      (bind
        sock
        addr
        (ftype-sizeof addr)))))

(udpsock-create
  (lambda (sock)
    (udpsock-reuseaddr sock)
    (udpsock-bind sock "0.0.0.0" 1337)
    (printf "~a~%" sock)))
