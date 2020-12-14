(library (schemelib bindings sodium)
  (export
    ; constants
    crypto_secretbox_KEYBYTES
    crypto_secretbox_MACBYTES
    crypto_secretbox_NONCEBYTES
    crypto_box_PUBLICKEYBYTES
    crypto_box_SECRETKEYBYTES
    crypto_box_MACBYTES
    crypto_box_SEALBYTES
    ; procedures
    sodium_init
    randombytes_buf
    sodium_increment
    crypto_box_keypair
    crypto_box_seal
    crypto_box_seal_open
    crypto_secretbox_easy
    crypto_secretbox_open_easy)
  (import (chezscheme))

  ;--- constants
  (define crypto_secretbox_KEYBYTES 32)
  (define crypto_secretbox_MACBYTES 16)
  (define crypto_secretbox_NONCEBYTES 24)

  (define crypto_box_PUBLICKEYBYTES 32)
  (define crypto_box_SECRETKEYBYTES 32)
  (define crypto_box_MACBYTES 16)
  (define crypto_box_SEALBYTES 
    (+ 
      crypto_box_PUBLICKEYBYTES
      crypto_box_MACBYTES))

  ;--- procedures
  (define (sodium_init)
    ((foreign-procedure "sodium_init" () int)))

  (define (randombytes_buf buf size)
    ((foreign-procedure "randombytes_buf" (u8* size_t) void) buf size))

  (define (sodium_increment n nlen)
    ((foreign-procedure "sodium_increment" (u8* size_t) void) n nlen))

  (define (crypto_box_keypair pk sk)
    ((foreign-procedure "crypto_box_keypair" (u8* u8*) int) pk sk))

  (define (crypto_box_seal c m mlen pk)
    ((foreign-procedure 
      "crypto_box_seal" 
      (u8* u8* unsigned-64 u8*) 
      int) c m mlen pk))

  (define (crypto_box_seal_open m c clen pk sk)
    ((foreign-procedure
      "crypto_box_seal_open"
      (u8* u8* unsigned-64 u8* u8*) 
      int) m c clen pk sk))

  (define (crypto_secretbox_easy c m mlen n k)
    ((foreign-procedure
      "crypto_secretbox_easy"
      (u8* u8* unsigned-64 u8* u8*)
      int) c m mlen n k))

  (define (crypto_secretbox_open_easy m c clen n k)
    ((foreign-procedure
      "crypto_secretbox_open_easy"
      (u8* u8* unsigned-long u8* u8*)
      int) m c clen n k))

  (load-shared-object "libsodium.so.23")
)
