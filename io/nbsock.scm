; nbsock
(define sockaddr-in-tmp 
  (make-ftype-pointer sockaddr_in 
    (foreign-alloc (ftype-sizeof sockaddr_in))))
(define ipv4str-tmp (make-ftype-pointer char (foreign-alloc INET_ADDRSTRLEN)))
(define socklen-tmp (make-ftype-pointer socklen_t (foreign-alloc (ftype-sizeof socklen_t))))
(define int-tmp (foreign-alloc (ftype-sizeof int)))

(define (nb-sock host port)
  ; create sock
  (let ([s (socket 'AF_INET '(SOCK_STREAM SOCK_NONBLOCK) 'IPPROTO_IP)])
    (assert (not (= -1 s)))
    
    ; build sock addr
    (ftype-set! sockaddr_in (common family) sockaddr-in-tmp (domain->int 'AF_INET))
    (ftype-set! sockaddr_in (port) sockaddr-in-tmp (htons port))
    (inet_pton
      'AF_INET
      host
      (ftype-&ref sockaddr_in (addr) sockaddr-in-tmp))

    ; allow reuse
    (foreign-set! 'int int-tmp 0 1)
    (setsockopt s 'SOL_SOCKET 'SO_REUSEADDR int-tmp (ftype-sizeof int))
    
    ;bind
    (assert (= 0 (bind s sockaddr-in-tmp (ftype-sizeof sockaddr_in))))

    s))

(define (nb-listen host port)
  (let ([s (nb-sock host port)])
    (assert (= (listen s 1024) 0))
    s))

(define (nb-accept sockfd)
  (let ([nfd (accept4 sockfd sockaddr-in-tmp socklen-tmp 'SOCK_NONBLOCK)])
    (assert (not (= -1 nfd)))
    (assert (= (ftype-sizeof sockaddr_in) (ftype-ref socklen_t () socklen-tmp)))
    (inet_ntop 'AF_INET (ftype-&ref sockaddr_in (addr) sockaddr-in-tmp) ipv4str-tmp INET_ADDRSTRLEN)
    `(,nfd
      ,(char*->string ipv4str-tmp INET_ADDRSTRLEN)
      ,(ntohs (ftype-ref sockaddr_in (port) sockaddr-in-tmp)))))


