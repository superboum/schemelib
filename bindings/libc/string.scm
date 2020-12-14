(library (schemelib bindings libc string)
  (export
    memcpy
    memcpy/u8*->void*
    memcpy/void*->u8*
    memset)
  (import (chezscheme))

  ;; string.h
  (define (memcpy dest src n)
    ((foreign-procedure "memcpy" (u8* u8* size_t) u8*) dest src n))

  (define (memcpy/u8*->void* dest src n)
    ((foreign-procedure "memcpy" (void* u8* size_t) void*) dest src n))

  (define (memcpy/void*->u8* dest src n)
    ((foreign-procedure "memcpy" (u8* void* size_t) u8*) dest src n))

  (define (memset s c n)
    ((foreign-procedure "memset" (void* int size_t) void*) s c n))

  (load-shared-object "libc.so.6")
)
