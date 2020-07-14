(include "bindings/libc.scm")
(include "bindings/utils.scm")

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

(define (configure-sockaddr_in! addr host port)
  (ftype-set! sockaddr_in (common family) addr (domain->int 'AF_INET))
  (ftype-set! sockaddr_in (port) addr (htons port))
  (check-err
    (inet_pton 
            'AF_INET 
            host
            (ftype-pointer-address
              (ftype-&ref sockaddr_in (addr) addr)))
          "Unable to convert your IP address to binary"))

(define (build-sockaddr_in host port cb)
  (alloc 
    (ftype-sizeof sockaddr_in)
    (lambda (raw-addr)
      (let ([addr (make-ftype-pointer sockaddr_in raw-addr)])
        (configure-sockaddr_in! addr host port)
        (cb addr)))))

(define (udpsock-bind sock host port)
  (build-sockaddr_in
    host port
    (lambda (addr)
      (bind
        sock
        (ftype-pointer-address addr)
        (ftype-sizeof sockaddr_in)))))

(define (udpsock-io sock fx)
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
        (fx
          (inet_ntop 
            'AF_INET 
            (ftype-pointer-address
              (ftype-&ref sockaddr_in (addr) addr))
              straddr
              straddrsize)
            (ntohs (ftype-ref sockaddr_in (port) addr))
            buf 
            nread
            (lambda (host port sendbuf sendbuflen) 
              (configure-sockaddr_in! addr host port)
              (sendto sock sendbuf sendbuflen 'MSG_DEFAULT addr (ftype-sizeof sockaddr_in))
            )))))

    (foreign-free (ftype-pointer-address straddr))
    (foreign-free (ftype-pointer-address addrlen))
    (foreign-free (ftype-pointer-address addr))
    (foreign-free buf)))
