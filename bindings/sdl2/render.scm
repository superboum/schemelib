(library (schemelib bindings sdl2 render)
  (export
    SDL_Rect
    SDL_RenderSetLogicalSize
    SDL_RenderSetScale
    SDL_CreateRenderer
    SDL_RenderReadPixels
    SDL_SetRenderDrawColor
    SDL_RenderGetViewport
    SDL_RenderClear
    SDL_RenderDrawPoint
    SDL_RenderPresent
    SDL_DestroyRenderer)
  (import (chezscheme))
  ;=== SDL_render.h

  ;--- mem. representation
  (define-ftype 
    [SdlRect
      (struct
        (x int) (y int)
        (w int) (h int)
  )])

  ;--- flags
  (define (SDL_RENDERER->int flag)
    (case flag
      ((SOFTWARE) #x00000001)
      ((ACCELERATED) #x00000002)
  ))

  ;--- allocs
  (define (SDL_Rect x y w h)
    (let [
      (rect 
        (make-ftype-pointer 
          SdlRect 
          (foreign-alloc (ftype-sizeof SdlRect))))]
    (ftype-set! SdlRect (x) rect x)
    (ftype-set! SdlRect (y) rect y)
    (ftype-set! SdlRect (w) rect w)
    (ftype-set! SdlRect (h) rect h)
    rect
  ))

  ;--- procedures
  (define (SDL_RenderSetLogicalSize rend w h)
    ((foreign-procedure
        "SDL_RenderSetLogicalSize"
        (void* int int)
        int) rend w h))

  (define (SDL_RenderSetScale rend scaleX scaleY)
    ((foreign-procedure
       "SDL_RenderSetScale"
       (void* float float)
       int) rend scaleX scaleY))

  (define (SDL_CreateRenderer window index flags)
    (let*
      [(fx (foreign-procedure 
            "SDL_CreateRenderer" 
            (void* int unsigned-32) 
            void*))
       (rend (fx window index (SDL_RENDERER->int flags)))]
      (assert (> rend 0))
      rend))

  (define (SDL_RenderReadPixels rend rect format pix pitch)
    ((foreign-procedure
      "SDL_RenderReadPixels"
      (void* (* SdlRect) unsigned-32 void* int)
      int) rend rect format pix pitch))

  (define (SDL_SetRenderDrawColor rend r g b a)
    ((foreign-procedure 
      "SDL_SetRenderDrawColor" 
      (void* unsigned-8 unsigned-8 unsigned-8 unsigned-8)
      int) rend r g b a))

  (define (SDL_RenderGetViewport rend rect)
    ((foreign-procedure
      "SDL_RenderGetViewport"
      (void* (* SdlRect))
      void) rend rect))

  (define (SDL_RenderClear rend)
    ((foreign-procedure
      "SDL_RenderClear"
      (void*)
      int) rend))

  (define (SDL_RenderDrawPoint rend x y)
    ((foreign-procedure
      "SDL_RenderDrawPoint"
      (void* int int)
      int) rend x y))

  (define (SDL_RenderPresent rend)
    ((foreign-procedure
      "SDL_RenderPresent"
      (void*)
      void) rend))

  (define (SDL_DestroyRenderer rend)
    ((foreign-procedure
      "SDL_DestroyRenderer"
      (void*)
      void) rend))

  (load-shared-object "libSDL2-2.0.so.0")
)
