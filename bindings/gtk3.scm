(library (schemelib bindings gtk3)
  (export
    gtk-init
    gtk-builder-new
    gtk-builder-add-from-file
    gtk-builder-get-object
    gtk-builder-connect-signals
    gtk-builder-add-callback-symbol
    gtk-widget-show
    gtk-widget-set-visible
    gtk-main
    gtk-main-quit)
  (import (chezscheme))

  (define (gtk-init argc argv)
    ((foreign-procedure "gtk_init" (ptr void*) void) argc argv))
  (define (gtk-builder-new)
    ((foreign-procedure "gtk_builder_new" () void*)))
  (define (gtk-builder-add-from-file builder filename err)
    ((foreign-procedure "gtk_builder_add_from_file" (void* string void*) void) builder filename err))
  (define (gtk-builder-get-object builder name)
    ((foreign-procedure "gtk_builder_get_object" (void* string) void*) builder name))
  (define (gtk-builder-connect-signals builder user-data)
    ((foreign-procedure "gtk_builder_connect_signals" (void* void*) void) builder user-data))
  (define (gtk-builder-add-callback-symbol builder cb-name cb-symbol)
    ((foreign-procedure "gtk_builder_add_callback_symbol" (void* string void*) void) builder cb-name cb-symbol))
  (define (gtk-widget-show widget)
    ((foreign-procedure "gtk_widget_show" (void*) void) widget))
  (define (gtk-widget-set-visible widget visibility)
    ((foreign-procedure "gtk_widget_set_visible" (void* boolean) void) widget visibility))
  (define (gtk-main)
    ((foreign-procedure "gtk_main" () void)))
  (define (gtk-main-quit)
    ((foreign-procedure "gtk_main_quit" () void)))

  (load-shared-object "libgtk-3.so.0")
)
