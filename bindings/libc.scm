(load-shared-object "libc.so.6")

(define (orflag->int flag-bind)
  (lambda (flag)
    (let ([lflag (cond ((list? flag) flag) (#t (list flag)))])
      (let f ([flag-iter lflag])
        (cond
          ((null? flag-iter) 0)
          (#t
            (bitwise-ior (cdr (assoc (car flag-iter) flag-bind)) (f (cdr flag-iter)))))))))

(define errno->int (orflag->int
  `((EAGAIN . 11)
    (EINTR . 4)
    (EINPROGRESS . 115))))

(define (errno)
  (foreign-ref 'int (foreign-entry "errno") 0))

;; string.h
(define (memcpy dest src n)
  ((foreign-procedure "memcpy" (u8* u8* size_t) u8*) dest src n))

(define (memcpy/u8*->void* dest src n)
  ((foreign-procedure "memcpy" (void* u8* size_t) void*) dest src n))

(define (memcpy/void*->u8* dest src n)
  ((foreign-procedure "memcpy" (u8* void* size_t) u8*) dest src n))

(define (memset s c n)
  ((foreign-procedure "memset" (void* int size_t) void*) s c n))

;;io

(define (cread fd buf count)
  ((foreign-procedure
    "read"
    (int u8* size_t) 
    ssize_t) fd buf count))

;;ioctl

(define ioctlreq->int (orflag->int
  `((SIOCOUTQ . 21521)
    (SIOCINQ . 21531))))

(define (ioctl fd req res)
  ((foreign-procedure
    "ioctl"
    (int unsigned-long void*)
    int) fd (ioctlreq->int req) res))

;; network
(define INET_ADDRSTRLEN 16)
(define INET6_ADDRSTRLEN 48)
(define (domain->int flag)
  (case flag
    ((AF_INET) 2)
))

(define type->int (orflag->int
  `((SOCK_STREAM . 1)
    (SOCK_DGRAM . 2)
    (SOCK_DCCP . 6)
    (SOCK_NONBLOCK . 2048))))

(define protocol->int (orflag->int
  `((IPPROTO_IP . 0)
    (IPPROTO_DCCP . 33))))

(define (perror str)
  ((foreign-procedure
     "perror"
     (string)
     void) str))

(define (socket domain type protocol)
  ((foreign-procedure
    "socket"
    (int int int)
    int)
     (domain->int domain)
     (type->int type) 
     (protocol->int protocol)))

(define-ftype 
  [socklen_t unsigned-32]
  [in_addr_t unsigned-32]
  [in_addr
    (packed (struct
      [addr in_addr_t]))]
  [sa_family_t unsigned-short]
  [in_port_t unsigned-16]
  [sockaddr_common 
    (struct
      [family sa_family_t])]
  [sockaddr 
    (struct
      [common sockaddr_common]
      [data (array 14 char)])]
  [sockaddr_in
    (packed (struct
      [common sockaddr_common]
      [port in_port_t]
      [addr in_addr]
      [zero (array 8 char)]))])

(define level->int (orflag->int
  `((SOL_SOCKET . #x1))))

(define optname->int (orflag->int
  `((SO_REUSEADDR . #x2)
    (SO_RCVBUF . #x8))))

(define (inet_pton af src dst)
  ((foreign-procedure
     "inet_pton"
     (int string (* in_addr))
     int)
    (domain->int af)
    src dst))

(define (inet_ntop af src dst size)
  ((foreign-procedure
     "inet_ntop"
     (int (* in_addr) (* char) unsigned-32)
     string)
     (domain->int af)
     src dst size))

(define (htons host)
  ((foreign-procedure "htons" (unsigned-16) unsigned-16) host))

(define (ntohs net)
  ((foreign-procedure "ntohs" (unsigned-16) unsigned-16) net))

(define (setsockopt sockfd level optname optval optlen)
  ((foreign-procedure
    "setsockopt"
    (int int int void* int)
    int) 
   sockfd 
   (level->int level)
   (optname->int optname)
   optval optlen))

(define (getsockopt sockfd level optname optval optlen)
  ((foreign-procedure
    "getsockopt"
    (int int int void* (* socklen_t))
    int) 
    sockfd 
    (level->int level)
    (optname->int optname)
    optval optlen))

(define (bind sockfd address address_len)
  ((foreign-procedure
     "bind"
     (int (* sockaddr_in) int)
     int) sockfd address address_len))

(define (listen sockfd backlog)
  ((foreign-procedure
     "listen"
     (int int)
     int) sockfd backlog))

(define (accept4 sockfd addr len flags)
  ((foreign-procedure
    "accept4"
    (int (* sockaddr_in) (* socklen_t) int)
    int) sockfd addr len (type->int flags)))

(define (connect sockfd addr addrlen)
  ((foreign-procedure
    "connect"
    (int (* sockaddr_in) socklen_t)
    int) sockfd addr addrlen))

(define msgflag->int (orflag->int
 `((MSG_DEFAULT . 0))))

(define (recv sockfd buf buflen flags)
  ((foreign-procedure
    "recv"
    (int u8* size_t int)
    ssize_t) sockfd buf buflen (msgflag->int flags)))

(define (recvfrom sockfd buf len msgflag src-addr addrlen)
  ((foreign-procedure
     "recvfrom"
     (int u8* size_t int (* sockaddr_in) (* socklen_t))
     int)
    sockfd
    buf
    len
    (msgflag->int msgflag)
    src-addr
    addrlen))

(define (send sockfd buf len flags)
  ((foreign-procedure
    "send"
    (int u8* size_t int) 
    ssize_t) sockfd buf len (msgflag->int flags)))

(define (close fd)
  ((foreign-procedure
    "close"
    (int) int) fd))

(define (sendto sockfd buf len msgflag dest-addr addrlen)
  ((foreign-procedure
     "sendto"
     (int u8* size_t int (* sockaddr_in) socklen_t)
     ssize_t)
    sockfd buf len
    (msgflag->int msgflag)
    dest-addr addrlen))

(define clock->int (orflag->int
  '((CLOCK_MONOTONIC . 1))))

(define timflag->int (orflag->int
  '((TFD_NONBLOCK . 2048))))

(define (timerfd_create clockid flags)
  ((foreign-procedure
    "timerfd_create"
    (int int) int) (clock->int clockid) (timflag->int flags)))

(define-ftype
  [time_t int]
  [timespec
    (struct
      [tv_sec time_t]
      [tv_nsec long])]

  [itimerspec
    (packed 
      (struct
        [it_interval timespec]
        [it_value timespec]))])

(define (timerfd_settime fd flags new_value old_value)
  ((foreign-procedure
    "timerfd_settime"
    (int int (* itimerspec) (* itimerspec))
    int) fd flags new_value old_value))

;--- epoll
(define-ftype 
  [epoll_data
    (union
      [ptr void*]
      [fd int]
      [u32 unsigned-32]
      [u64 unsigned-64])]

  [epoll_event
    (packed
      (struct
        [events unsigned-32]
        [data epoll_data]))])

(define (epoll_create size)
  ((foreign-procedure
    "epoll_create"
    (int) int) size))

(define (epoll_wait epfd events maxevents timeout)
  ((foreign-procedure
    "epoll_wait"
    (int (* epoll_event) int int) 
    int) epfd events maxevents timeout))

(define epoll-ctl->int (orflag->int
  `((EPOLL_CTL_ADD . 1)
    (EPOLL_CTL_DEL . 2)
    (EPOLL_CTL_MOD . 3))))

(define epoll-ev->int (orflag->int
  `((EPOLLIN . ,(expt 2 0))
    (EPOLLOUT . ,(expt 2 2))
    (EPOLLERR . ,(expt 2 3))
    (EPOLLHUP . ,(expt 2 4))
    (EPOLLRDHUP . ,(expt 2 13))
    (EPOLLET . ,(expt 2 31)))))

(define (epoll_ctl epfd op fd event)
  ((foreign-procedure
    "epoll_ctl"
    (int unsigned-int int (* epoll_event))
    int) epfd (epoll-ctl->int op) fd event))

(define (fcntl2 fd cmd)
  ((foreign-procedure
    "fcntl" (int int) int) fd cmd))

(define (fcntl3 fd cmd arg)
  ((foreign-procedure
    "fcntl" (int int int) int) fd cmd arg))
