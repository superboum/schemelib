(load-shared-object "libgobject-2.0.so")

(define (g-object-set object property value)
  ((foreign-procedure "g_object_set" (void* string string void*) void) object property value 0))
(define (g-signal-connect-data instance detailed-signal handler data destroy-data connect-flag)
  ((foreign-procedure "g_signal_connect_data" (void* string void* void* void* int) void)
     instance detailed-signal handler data destroy-data connect-flag))
(define (g-signal-connect instance detailed-signal handler data)
  (g-signal-connect-data instance detailed-signal handler data 0 0))
(define (g-object-unref object)
  ((foreign-procedure "g_object_unref" (void*) void) object))
  
