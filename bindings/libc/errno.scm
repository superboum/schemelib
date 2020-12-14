(library (schemelib bindings libc errno)
  (export
    errno->int
    errno
    perror)
  (import 
    (schemelib bindings libc helpers) 
    (chezscheme))

  (define errno->int (orflag->int
    `((EAGAIN . 11)
      (EINTR . 4)
      (EINPROGRESS . 115))))

  (define (errno)
    (foreign-ref 'int (foreign-entry "errno") 0))

  (define (perror str)
    ((foreign-procedure
      "perror"
      (string)
      void) str))

  (load-shared-object "libc.so.6")
)
