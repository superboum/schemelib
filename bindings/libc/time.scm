(library (schemelib bindings libc time)
  (export
    ; mem. representation
    time_t timespec tv_sec tv_nsec
    itimerspec it_interval it_value
    ; flags
    clock->int
    timflag->int
    ; procedures
    timerfd_create
    timerfd_settime)
  (import 
    (schemelib bindings libc helpers)
    (chezscheme))

  ;--- mem. representation
  (define-ftype
    [time_t int]
    [timespec
      (struct
        [tv_sec time_t]
        [tv_nsec long])]

    [itimerspec
      (packed 
        (struct
          [it_interval timespec]
          [it_value timespec]))])

  ;--- flags
  (define clock->int (orflag->int
    '((CLOCK_MONOTONIC . 1))))

  (define timflag->int (orflag->int
    '((TFD_NONBLOCK . 2048))))

  ;--- procedures
  (define (timerfd_create clockid flags)
    ((foreign-procedure
      "timerfd_create"
      (int int) int) (clock->int clockid) (timflag->int flags)))

  (define (timerfd_settime fd flags new_value old_value)
    ((foreign-procedure
      "timerfd_settime"
      (int int (* itimerspec) (* itimerspec))
      int) fd flags new_value old_value))

  (load-shared-object "libc.so.6")
)
