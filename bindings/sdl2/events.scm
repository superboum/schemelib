(library (schemelib bindings sdl2 events)
  (export
    ; mem. representation
    SdlEvent
    ; flags
    SDL_EVENT->flag
    ; alloc
    SDL_Event
    ; procedures
    SDL_PollEvent
    )
  (import (chezscheme))
  ;=== SDL_events.h

  ;--- mem. representation
  (define-ftype 
    [SdlEvent
      (union
        (type unsigned-32)
        (padding (array 56 unsigned-8)))]
  )

  ;--- flags
  (define (SDL_EVENT->flag i)
    (case i
      ((#x100) 'QUIT)
  ))

  ;--- alloc
  (define (SDL_Event)
    (make-ftype-pointer 
      SdlEvent 
      (foreign-alloc (ftype-sizeof SdlEvent))))

  ;--- procedures 
  (define (SDL_PollEvent event)
    ((foreign-procedure
      "SDL_PollEvent"
      ((* SdlEvent))
     int) event))

  (load-shared-object "libSDL2-2.0.so.0")
)
