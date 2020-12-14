; A quick example:
; https://stackoverflow.com/questions/20579658/how-to-draw-pixels-in-sdl-2-0
;
; Header files to write bindings:
; https://github.com/SDL-mirror/SDL/tree/master/include
; https://github.com/SDL-mirror/SDL_image/blob/master/SDL_image.h

(library (schemelib bindings sdl2 core)
  (export
    SDL_Init
    SDL_Quit)
  (import (chezscheme))
  ;=== SDL.h

  ;--- flags
  (define (SDL_INIT->int flag)
    (case flag
      ((VIDEO) #x00000020)
  ))

  ;--- procedures
  (define (SDL_Init flag)
    ((foreign-procedure "SDL_Init" (unsigned-32) int) (SDL_INIT->int flag)))

  (define (SDL_Quit)
    ((foreign-procedure "SDL_Quit" () void)))

  (load-shared-object "libSDL2-2.0.so.0")
)
