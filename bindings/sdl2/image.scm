(library (schemelib bindings sdl2 image)
  (export IMG_SavePNG)
  (import 
    (schemelib bindings sdl2 surface)
    (chezscheme))

  ;--- SDL_image.h
  (define (IMG_SavePNG surface file)
    ((foreign-procedure
      "IMG_SavePNG"
      ((* SdlSurface) string)
      int) surface file))

  (load-shared-object "libSDL2_image-2.0.so.0")
)
