(library (schemelib bindings sdl2 video)
  (export
    SDL_CreateWindow
    SDL_SetWindowSize
    SDL_DestroyWindow)
  (import (chezscheme))
  ;=== SDL_video.h

  ;--- flags
  (define (SDL_WINDOW->int flag)
    (case flag
      ((SHOW) #x00000004)
      ((FOREIGN) #x00000800)
      ((HIDDEN) #x00000008)
  ))

  ;--- procedures
  (define (SDL_CreateWindow name x y w h flags)
    (let* 
      [(fx (foreign-procedure 
               "SDL_CreateWindow" 
               (string int int int int unsigned-32) 
               void*))
        (win (fx name x y w h (SDL_WINDOW->int flags)))]
      (assert (> win 0))
      win))

  (define (SDL_SetWindowSize win w h)
    ((foreign-procedure 
      "SDL_SetWindowSize"
      (void* int int)
      void) win w h))

  (define (SDL_DestroyWindow window)
    ((foreign-procedure
      "SDL_DestroyWindow"
      (void*)
      void) window))

  (load-shared-object "libSDL2-2.0.so.0")
)
