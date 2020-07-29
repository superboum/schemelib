; nbsock
(define sockaddr-in-tmp 
  (make-ftype-pointer sockaddr_in 
    (foreign-alloc (ftype-sizeof sockaddr_in))))
(define ipv4str-tmp (make-ftype-pointer char (foreign-alloc INET_ADDRSTRLEN)))
(define socklen-tmp (make-ftype-pointer socklen_t (foreign-alloc (ftype-sizeof socklen_t))))
(define int-tmp (foreign-alloc (ftype-sizeof int)))

(define (nb-build-sockaddr host port)
  (memset (ftype-pointer-address sockaddr-in-tmp) 0 (ftype-sizeof sockaddr_in))
  (ftype-set! sockaddr_in (common family) sockaddr-in-tmp (domain->int 'AF_INET))
  (ftype-set! sockaddr_in (port) sockaddr-in-tmp (htons port))
  (inet_pton
    'AF_INET
    host
    (ftype-&ref sockaddr_in (addr) sockaddr-in-tmp)))
(define (nb-sock host port)
  ; create sock
  (let ([s (socket 'AF_INET '(SOCK_STREAM SOCK_NONBLOCK) 'IPPROTO_IP)])
    (assert (not (= -1 s)))
    
    ; build sock addr
    (nb-build-sockaddr host port)

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

(define (nb-connect srchost desthost destport)
  (memset (ftype-pointer-address sockaddr-in-tmp) 0 (ftype-sizeof sockaddr_in))
  (ftype-set! socklen_t () socklen-tmp (ftype-sizeof sockaddr_in))
  (let ([s (nb-sock srchost 0)])
    (nb-build-sockaddr desthost destport)
    `(,s
      .
      ,(connect s sockaddr-in-tmp (ftype-sizeof sockaddr_in)))))

(define ioctlres (foreign-alloc (ftype-sizeof unsigned-long)))
(define getsockoptval (foreign-alloc (ftype-sizeof int)))
(define getsockoptvallen (make-ftype-pointer socklen_t (foreign-alloc (ftype-sizeof socklen_t))))
(define (nb-outq-free fd)
  (foreign-set! 'unsigned-long ioctlres 0 0)
  (cond
    ((= (ioctl fd 'SIOCOUTQ ioctlres) -1)
      (perror "failure:")
      (raise "ioctl call failed")))

  (foreign-set! 'int getsockoptval 0 0)
  (ftype-set! socklen_t () getsockoptvallen (ftype-sizeof int))
  (cond
    ((= (getsockopt fd 'SOL_SOCKET 'SO_RCVBUF getsockoptval getsockoptvallen) -1)
      (perror "failure: ")
      (raise "getsockopt call failed")))
  (assert (= (ftype-sizeof int) (ftype-ref socklen_t () getsockoptvallen)))

  (- 
    (foreign-ref 'int getsockoptval 0)
    (foreign-ref 'unsigned-long ioctlres 0))
)

(define (nb-new-itimerspec) 
  (make-ftype-pointer itimerspec (foreign-alloc (ftype-sizeof itimerspec))))
(define nb-timer-tmp-new (nb-new-itimerspec))
(define nb-timer-tmp-old (make-ftype-pointer itimerspec 0))
(define (nb-timer secs)
  (memset (ftype-pointer-address nb-timer-tmp-new) 0 (ftype-sizeof itimerspec))
  (let ([fd (timerfd_create 'CLOCK_MONOTONIC 'TFD_NONBLOCK)])
    (assert (not (= -1 fd)))
    (ftype-set! itimerspec (it_interval tv_sec) nb-timer-tmp-new secs)
    (ftype-set! itimerspec (it_value tv_sec) nb-timer-tmp-new secs)
    (assert (= (timerfd_settime fd 0 nb-timer-tmp-new nb-timer-tmp-old) 0))
    fd))
(define nb-timer-ticks (make-bytevector (ftype-sizeof unsigned-64)))
(define (nb-timer-ack fd)
  (cread fd nb-timer-ticks (bytevector-length nb-timer-ticks))
  (bytevector-u64-ref nb-timer-ticks 0 (native-endianness)))

(define (inet-ntop in_addr)
  (inet_ntop 'AF_INET in_addr ipv4str-tmp INET_ADDRSTRLEN)
  (char*->string ipv4str-tmp INET_ADDRSTRLEN))

(define (nb-accept sockfd)
  (memset (ftype-pointer-address sockaddr-in-tmp) 0 (ftype-sizeof sockaddr_in))
  (ftype-set! socklen_t () socklen-tmp (ftype-sizeof sockaddr_in))
  (let ([nfd (accept4 sockfd sockaddr-in-tmp socklen-tmp 'SOCK_NONBLOCK)])
    ;(assert (not (= -1 nfd)))
    ;(assert (= (ftype-sizeof sockaddr_in) (ftype-ref socklen_t () socklen-tmp)))
    (cond
      ((= -1 nfd) `(,nfd #f #f))
      (#t
       `(,nfd
         ,(inet-ntop (ftype-&ref sockaddr_in (addr) sockaddr-in-tmp))
         ,(ntohs (ftype-ref sockaddr_in (port) sockaddr-in-tmp)))))))


