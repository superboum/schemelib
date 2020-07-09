(load-shared-object "libc.so.6")

(define (domain-flag->int flag)
  (case flag
    ((AF_INET) 2)
))

(define (type-flag->int flag)
  (case flag
    ((SOCK_DGRAM) 2)
    ((SOCK_DCCP) 6)
))

(define (protocol-flag->int flag)
  (case flag
    ((IPPROTO_NONE) 0)
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
     (domain-flag->int domain)
     (type-flag->int type) 
     (protocol-flag->int protocol)))
