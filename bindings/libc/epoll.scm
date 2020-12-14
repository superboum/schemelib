(library (schemelib bindings libc epoll)
  (export
    ; mem. representation
    epoll_data
    epoll_event
    ; flags
    epoll-ctl->int
    epoll-ev->int
    ; procedures
    epoll_create
    epoll_wait
    epoll_ctl)
  (import 
    (schemelib bindings libc helpers)
    (chezscheme))

  ;--- mem. representation
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

  ;--- flags
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

  ;--- procedures
  (define (epoll_create size)
    ((foreign-procedure
      "epoll_create"
      (int) int) size))

  (define (epoll_wait epfd events maxevents timeout)
    ((foreign-procedure
      "epoll_wait"
      (int (* epoll_event) int int) 
      int) epfd events maxevents timeout))

  (define (epoll_ctl epfd op fd event)
    ((foreign-procedure
      "epoll_ctl"
      (int unsigned-int int (* epoll_event))
      int) epfd (epoll-ctl->int op) fd event))

  (load-shared-object "libc.so.6")
)
