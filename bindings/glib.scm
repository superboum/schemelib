(load-shared-object "libglib-2.0.so.0")

(define (g-main-loop-new context is-running)
  ((foreign-procedure "g_main_loop_new" (void* boolean) void*) context is-running))
(define (g-main-loop-run loop)
  ((foreign-procedure "g_main_loop_run" (void*) void) loop))
(define (g-main-loop-quit loop)
  ((foreign-procedure "g_main_loop_quit" (void*) void) loop))
  
