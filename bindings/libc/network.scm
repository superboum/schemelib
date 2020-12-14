(library (schemelib bindings libc network)
  (export
    ; constants
    INET_ADDRSTRLEN INET6_ADDRSTRLEN
    ; mem. representation
    socklen_t in_addr_t in_addr
    sa_family_t in_port_t sockaddr_common
    sockaddr sockaddr_in
    ; flags
    domain->int type->int protocol->int level->int
    optname->int msgflag->int
    ; procedures
    inet_pton inet_ntop htons ntohs
    setsockopt getsockopt
    socket bind listen accept4 connect
    recv recvfrom send sendto)
  (import 
    (schemelib bindings libc helpers)
    (chezscheme))

  ;--- constants
  (define INET_ADDRSTRLEN 16)
  (define INET6_ADDRSTRLEN 48)

  ;--- mem. representation
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

  ;--- flags
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

  (define level->int (orflag->int
    `((SOL_SOCKET . #x1))))

  (define optname->int (orflag->int
    `((SO_REUSEADDR . #x2)
      (SO_RCVBUF . #x8))))

  (define msgflag->int (orflag->int
    `((MSG_DEFAULT . 0))))

  ;--- procedures
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

  (define (socket domain type protocol)
    ((foreign-procedure
        "socket"
        (int int int)
        int)
      (domain->int domain)
      (type->int type) 
      (protocol->int protocol)))


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

  (define (sendto sockfd buf len msgflag dest-addr addrlen)
    ((foreign-procedure
        "sendto"
        (int u8* size_t int (* sockaddr_in) socklen_t)
        ssize_t)
      sockfd buf len
      (msgflag->int msgflag)
      dest-addr addrlen))

  (load-shared-object "libc.so.6")
)
