(library (schemelib bindings sdl2 surface)
  (export
    ; mem. representation
    SdlSurface
    ; procedures
    SDL_CreateRGBSurface
    SDLb_SetPixel)
  (import (chezscheme))
  ;=== SDL_surface.h

  ; mem. representation
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

  ;--- procedures
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

  (load-shared-object "libSDL2-2.0.so.0")
)
