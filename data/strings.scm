(library (schemelib data strings)
  (export
    string-suffix?
    string-prefix?
    string-contains?)
  (import 
    (schemelib io ports)
    (chezscheme))

  (define (string-suffix? src suffix)
    (let [(src-len (string-length src)) (suf-len (string-length suffix))]
      (and 
        (>= src-len  suf-len) 
        (string=? suffix (substring src (- src-len suf-len) src-len))
  )))

  (define (string-prefix? src prefix)
    (let [(src-len (string-length src)) (pref-len (string-length prefix))]
      (and
        (>= src-len pref-len)
        (string=? prefix (substring src 0 pref-len))
  )))

  (define (string-contains? src elem) ; we use port logic to implement this one
    (seek-until (open-input-string src) elem))
)
