(library (schemelib io filesystem)
  (export 
    build-path
    walk-rec
    walk)
  (import (chezscheme))

  (define (build-path p1 p2)
    (format "~a~a~a" p1 (directory-separator) p2))

  (define (walk-rec path subpath)
    (cond
      ((null? subpath) '())
      (#t (append (walk (build-path path (car subpath))) (walk-rec path (cdr subpath))))
  ))

  (define (walk path)
    (cond
      ((file-directory? path) (walk-rec path (directory-list path)))
      (#t (list path))))
