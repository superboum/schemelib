(load-shared-object "libc.so.6")

(define (domain->int flag)
  (case flag
    ((AF_INET) 2)
))

(define (type->int flag)
  (case flag
    ((SOCK_DGRAM) 2)
    ((SOCK_DCCP) 6)
))

(define (protocol->int flag)
  (case flag
    ((IPPROTO_IP) 0)
    ((IPPROTO_DCCP) 33)
))

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
  [in_addr
    (struct
      (s_addr unsigned-long))]

  [sockaddr_in
    (struct
      (sin_family short)
      (sin_port unsigned-short)
      (sin_addr in_addr)
      (sin_zero (array 8 char)))]
)

(define (level->int flag)
   (case flag
    ((SOL_SOCKET) #x1)
))

(define (optname->int flag)
   (case flag
    ((SO_REUSEADDR) #x2)
))

(define (inet_pton af src dst)
  ((foreign-procedure
     "inet_pton"
     (int string void*)
     int)
    (domain->int af)
    src dst))

(define (htons host)
  ((foreign-procedure
     "htons"
     (short)
     short) host))

(define (setsockopt sockfd level optname optval optlen)
  ((foreign-procedure
    "setsockopt"
    (int int int void* int)
    int) 
   sockfd 
   (level->int level)
   (optname->int optname)
   optval optlen))

(define (bind sockfd address address_len)
  ((foreign-procedure
     "bind"
     (int void* int)
     int) sockfd address address_len))


