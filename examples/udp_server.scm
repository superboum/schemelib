(load "../bindings/libc.scm")
(load "../bindings/utils.scm")

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

(define (udpsock-bind sock host port)
  (alloc 
    (ftype-sizeof sockaddr_in)
    (lambda (raw-addr)
      (let ([addr (make-ftype-pointer sockaddr_in raw-addr)])
        (ftype-set! sockaddr_in (common family) addr (domain->int 'AF_INET))
        (ftype-set! sockaddr_in (port) addr (htons port))
        (check-err
          (inet_pton 
            'AF_INET 
            host
            (ftype-pointer-address
              (ftype-&ref sockaddr_in (addr) addr)))
          "Unable to convert your IP address to binary")
        (bind
          sock
          (ftype-pointer-address addr)
          (ftype-sizeof sockaddr_in))))))

(define (udpsock-readblock sock fx)
  (letrec* 
    ([bufsize 1500] [straddrsize 255]
     [buf (foreign-alloc bufsize)]
     [straddr (make-ftype-pointer char
                (foreign-alloc straddrsize))]
     [addrlen (make-ftype-pointer socklen_t 
                (foreign-alloc (ftype-sizeof socklen_t)))]
     [_ (ftype-set! socklen_t () addrlen (ftype-sizeof sockaddr_in))]
     [addr (make-ftype-pointer 
             sockaddr_in 
             (foreign-alloc (ftype-sizeof sockaddr_in)))]
     [loop (lambda (ifx) (cond ((ifx) (loop ifx)) (#t #t)))])

    (loop 
      (lambda ()
        (let ([nread (recvfrom sock buf bufsize 'MSG_DEFAULT addr addrlen)])
        (printf "~a~%" (ftype-pointer->sexpr addr))
        (fx
          (inet_ntop 
            'AF_INET 
            (ftype-pointer-address
              (ftype-&ref sockaddr_in (addr) addr))
              straddr
              straddrsize)
            (ntohs (ftype-ref sockaddr_in (port) addr))
            buf nread))))

    (foreign-free (ftype-pointer-address straddr))
    (foreign-free (ftype-pointer-address addrlen))
    (foreign-free (ftype-pointer-address addr))
    (foreign-free buf)))

(udpsock-create
  (lambda (sock)
    (udpsock-reuseaddr sock)
    (udpsock-bind sock "127.0.0.8" 1337)
    (udpsock-readblock 
      sock 
      (lambda (host port buf size)
        (printf 
          "host: ~a, port: ~a, size: ~a, buf: ~a~%"
          host port size 
          (char*->string
            (make-ftype-pointer char buf)
            size))
))))
