(library (schemelib bindings libc ioctl)
  (export     
    ioctlreq->int
    ioctl)
  (import
    (schemelib bindings libc helpers)
    (chezscheme))

  (define ioctlreq->int (orflag->int
    `((SIOCOUTQ . 21521)
      (SIOCINQ . 21531))))

  (define (ioctl fd req res)
    ((foreign-procedure
      "ioctl"
      (int unsigned-long void*)
      int) fd (ioctlreq->int req) res))

  (load-shared-object "libc.so.6")
)
