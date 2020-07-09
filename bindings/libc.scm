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
  [socklen_t unsigned-32]
  [in_addr_t unsigned-32]
  [in_addr
    (struct
      [addr in_addr_t])]
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
    (struct
      [common sockaddr_common]
      [port in_port_t]
      [addr in_addr]
      [zero (array 8 char)])])

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

(define (inet_ntop af src dst size)
  ((foreign-procedure
     "inet_ntop"
     (int void* (* char) unsigned-32)
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

(define (bind sockfd address address_len)
  ((foreign-procedure
     "bind"
     (int void* int)
     int) sockfd address address_len))

(define (listen sockfd backlog)
  ((foreign-procedure
     "listen"
     (int int)
     int) sockfd backlog))

(define (msgflag->int flag)
  (case flag
    ((MSG_DEFAULT) 0)
))

(define (recvfrom sockfd buf len msgflag src-addr addrlen)
  ((foreign-procedure
     "recvfrom"
     (int void* size_t int (* sockaddr_in) (* socklen_t))
     int)
    sockfd
    buf
    len
    (msgflag->int msgflag)
    src-addr
    addrlen))
