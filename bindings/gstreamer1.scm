(load-shared-object "libgstreamer-1.0.so.0"))

; Data structures
(define (gst-message->symbol int)
  (case int
    ((1) 'eos)
    ((2) 'error)))

(define (gst-state->int symbol) 
  (case symbol
    ((void-pending) 0)
    ((null)         1)
    ((ready)        2)
    ((paused)       3)
    ((playing)      4)))

(define-ftype gst-mini-object
  (struct
    [type unsigned-long]
    [refcount int]
    [lockstate int]
    [flags unsigned-int]
    [copy void*]
    [dispose void*]
    [free void*]
    [n-qdata unsigned-int]
    [qdata void*]))

(define-ftype gst-message
  (struct
    [mini-object gst-mini-object]
    [type int]
    [timestamp unsigned-64]
    [src void*]
    [seqnum unsigned-32]
    [lock void*]
    [cond void*]))

(define (gst-init argc argv)
  ((foreign-procedure "gst_init" (ptr void*) void) argc argv))
(define (gst-element-factory-make factory-name name)
  ((foreign-procedure "gst_element_factory_make" (string string) void*) factory-name name))
(define (gst-pipeline-get-bus pipeline)
  ((foreign-procedure "gst_pipeline_get_bus" (void*) void*) pipeline))
(define (gst-bus-add-watch bus func user-data)
  ((foreign-procedure "gst_bus_add_watch" (void* void* void*) int) bus func user-data))
(define (gst-bus-add-signal-watch bus)
  ((foreign-procedure "gst_bus_add_signal_watch" (void*) void) bus))
(define (gst-object-unref object)
  ((foreign-procedure "gst_object_unref" (void*) void) object))
(define (gst-element-set-state element state)
  ((foreign-procedure "gst_element_set_state" (void* int) int) element state))
(define (gst-filename-to-uri filename err)
  ((foreign-procedure "gst_filename_to_uri" (string void*) string) filename err))

