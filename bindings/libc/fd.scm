(library (schemelib bindings libc fd)
  (export
    read/char*
    fcntl2
    fcntl3
    close)
  (import (chezscheme))

  (define (read/char* fd buf count)
    ((foreign-procedure
      "read"
      (int u8* size_t) 
      ssize_t) fd buf count))

  (define (fcntl2 fd cmd)
    ((foreign-procedure
      "fcntl" (int int) int) fd cmd))

  (define (fcntl3 fd cmd arg)
    ((foreign-procedure
      "fcntl" (int int int) int) fd cmd arg))

  (define (close fd)
    ((foreign-procedure
      "close"
      (int) int) fd))

  (load-shared-object "libc.so.6")
)
