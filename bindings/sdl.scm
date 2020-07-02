(load-shared-object "libSDL2-2.0.so.0")
(load-shared-object "libSDL2_image-2.0.so.0")

; A quick example:
; https://stackoverflow.com/questions/20579658/how-to-draw-pixels-in-sdl-2-0
;
; Header files to write bindings:
; https://github.com/SDL-mirror/SDL/tree/master/include
; https://github.com/SDL-mirror/SDL_image/blob/master/SDL_image.h

;--- binding utils
(define (check-err out)
  (assert (= 0 out)))

;--- SDL.h
(define (SDL_INIT-flag->int flag)
    (case flag
      ((VIDEO) #x00000020)
))

(define (SDL_Init flag)
  (check-err ((foreign-procedure "SDL_Init" (unsigned-32) int) (SDL_INIT-flag->int flag))))

(define (SDL_Quit)
  ((foreign-procedure "SDL_Quit" () void)))

;--- SDL_video.h
(define (SDL_WINDOW-flag->int flag)
    (case flag
      ((SHOW) #x00000004)
      ((FOREIGN) #x00000800)
      ((HIDDEN) #x00000008)
))

(define (SDL_CreateWindow name x y w h flags)
  (let* 
    [(fx (foreign-procedure 
             "SDL_CreateWindow" 
             (string int int int int unsigned-32) 
             void*))
      (win (fx name x y w h (SDL_WINDOW-flag->int flags)))]
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

;--- SDL_render.h
(define-ftype 
  [SdlRect
    (struct
      (x int) (y int)
      (w int) (h int)
)])

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

(define (SDL_RenderSetLogicalSize rend w h)
  (check-err
    ((foreign-procedure
      "SDL_RenderSetLogicalSize"
      (void* int int)
      int) rend w h)))

(define (SDL_RenderSetScale rend scaleX scaleY)
  (check-err
    ((foreign-procedure
       "SDL_RenderSetScale"
       (void* float float)
       int) rend scaleX scaleY)))

(define (SDL_RENDERER-flag->int flag)
    (case flag
      ((SOFTWARE) #x00000001)
      ((ACCELERATED) #x00000002)
))

(define (SDL_CreateRenderer window index flags)
  (let*
    [(fx (foreign-procedure 
           "SDL_CreateRenderer" 
           (void* int unsigned-32) 
           void*))
     (rend (fx window index (SDL_RENDERER-flag->int flags)))]
    (assert (> rend 0))
    rend))

(define (SDL_RenderReadPixels rend rect format pix pitch)
  (check-err 
    ((foreign-procedure
      "SDL_RenderReadPixels"
      (void* (* SdlRect) unsigned-32 void* int)
      int) rend rect format pix pitch)))

(define (SDL_SetRenderDrawColor rend r g b a)
  (check-err
    ((foreign-procedure 
      "SDL_SetRenderDrawColor" 
      (void* unsigned-8 unsigned-8 unsigned-8 unsigned-8)
      int) rend r g b a)))

(define (SDL_RenderGetViewport rend rect)
  ((foreign-procedure
     "SDL_RenderGetViewport"
     (void* (* SdlRect))
     void) rend rect))

(define (SDL_RenderClear rend)
  (check-err
    ((foreign-procedure
       "SDL_RenderClear"
       (void*)
       int) rend)))

(define (SDL_RenderDrawPoint rend x y)
  (check-err
    ((foreign-procedure
      "SDL_RenderDrawPoint"
      (void* int int)
      int) rend x y)))

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

;--- SDL_surface.h
(define-ftype 
  [SdlPixelFormat
    (struct
      (format unsigned-32)
      ;-- not safe to allocate, missing fields
  )]

  [SdlSurface
    (struct
      (flags unsigned-32)
      (format (* SdlPixelFormat))
      (w int)
      (h int)
      (pitch int)
      (pixels void*)
      ;-- not safe to allocate, missing fields
)])

(define (SDL_CreateRGBSurface flags w h depth Rm Gm Bm Am)
  ((foreign-procedure
     "SDL_CreateRGBSurface"
     (unsigned-32 int int int unsigned-32 unsigned-32 unsigned-32 unsigned-32)
     (* SdlSurface)) flags w h depth Rm Gm Bm Am))

; inspired by https://stackoverflow.com/a/20070273
(define (SDLb_SetPixel surface x y r g b a)
  (map
    (lambda (e)
      (let [(color (car e)) (intensity (cadr e))]
        (foreign-set! 
          'unsigned-8
          (ftype-ref SdlSurface (pixels) surface)
          (+ 
            (* y (ftype-ref SdlSurface (pitch) surface))
            (* x (ftype-sizeof unsigned-32))
            color)
          intensity
    )))
    `((0 ,b) (1 ,g) (2 ,r) (3 ,a)) 
))

;--- SDL_events.h
(define-ftype 
  [SdlEvent
    (union
      (type unsigned-32)
      (padding (array 56 unsigned-8)))]
)

(define (SDL_Event)
  (make-ftype-pointer 
    SdlEvent 
    (foreign-alloc (ftype-sizeof SdlEvent))))

(define (SDL_PollEvent event)
  ((foreign-procedure
     "SDL_PollEvent"
     ((* SdlEvent))
     int) event))

(define (SDL_EVENT-int->flag i)
    (case i
      ((#x100) 'QUIT)
))

;--- SDL_image.h
(define (IMG_SavePNG surface file)
  (check-err
    ((foreign-procedure
       "IMG_SavePNG"
       ((* SdlSurface) string)
       int) surface file)))



