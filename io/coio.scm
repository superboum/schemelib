(define epfd #f)
(define ev #f)
(define events #f)
(define max-events #f)
(define fdrecv '())
(define listen-sock #f)
(define reco-sock #f)
(define hostaddr #f)
(define hardcoded-port 3500)

; ip <-> idx
(define (baseip) (bytevector-copy #vu8(127 0 1 0)))
(define inaddrbuf (foreign-alloc (ftype-sizeof in_addr)))
(define (idx->ip idx)
  (let ([newip (baseip)])
    (bytevector-u32-set! 
      newip
      0
      (+
        (bytevector-u32-ref newip 0 'big)
        idx)
      'big)

    (memcpy/u8*->void* inaddrbuf newip (bytevector-length newip))
    (inet-ntop (make-ftype-pointer in_addr inaddrbuf))))
(define (ip->idx host)
  (let ([ipbv (make-bytevector 4)])
    (inet_pton 'AF_INET host (make-ftype-pointer in_addr inaddrbuf))
    (memcpy/void*->u8* ipbv inaddrbuf (bytevector-length ipbv))
    (-
     (bytevector-u32-ref ipbv 0 'big)
     (bytevector-u32-ref (baseip) 0 'big))))

; generic
(define (iostatus res)
  (cond
    ((and 
       (= -1 res) 
       (or 
         (= (errno) (errno->int 'EINPROGRESS)) 
         (= (errno) (errno->int 'EAGAIN)))) 'not-ready)
    ((= -1 res) 'fatal)
    (#t 'ok)))

; handle connections here (accept, connect, broken, up)
(define fds (make-eq-hashtable))
(define hosts (make-hashtable string-hash string=?))
(define pristine (make-eq-hashtable))
(define sendbroken '())
(define connectready '())

(define (coio-accept fd) 
  (coio-fd-register (nb-accept fd)))

(define (coio-connect dest)
  (cond
    ((not (null? (hashtable-ref hosts (aget 'host dest) '()))) #t)
    (#t
      (let* ([r (nb-connect hostaddr (aget 'host dest) hardcoded-port)]
             [err (errno)]
             [rdy (= (cdr r) 0)]
             [prog (and (= (cdr r) -1) (= err (errno->int 'EINPROGRESS)))])
        (cond
          ((or rdy prog) (coio-fd-register `(,(car r) ,(aget 'host dest))))
          (#t (perror "failed to connect") (raise "unsupported error")))
       ))))

(define (coio-fd-register client)
  (hashtable-set! pristine (car client) #t)
  (hashtable-set! fds (car client) (cadr client))
  (hashtable-update! hosts (cadr client) (lambda (v) (cons (car client) v)) '())
  (epoll-add epfd (car client) '(EPOLLRDHUP EPOLLIN EPOLLOUT EPOLLET) ev))

(define (coio-handle-pristine fd)
  (hashtable-delete! pristine fd)
  (set! connectready (cons fd connectready))
  (printf "handlepri: ~a~%" connectready)
  (co-unlock 'connectready))

(define (coio-ready)
  (printf "loop: ~a~%" connectready)
  (cond
    ((null? connectready) (co-lock 'connectready) (coio-ready))
    (#t 
      (let ([v (hashtable-ref fds (car connectready) #f)])
        (set! connectready (cdr connectready))
        (cond
          ((not v) (coio-ready))
          (#t v))))))

(define (coio-reconnect)
  (cond
    ((null? sendbroken) #t)
    ((not (null? (hashtable-ref hosts (car sendbroken) '())))
      (set! sendbroken (cdr sendbroken))
      (coio-reconnect))
    (#t
      (printf "reconnecting ~a~%" (car sendbroken))
      (coio-connect `((host . ,(car sendbroken))))
      (set! sendbroken (cdr sendbroken)))))
      
(define (coio-fd-broken fd)
  (printf "~a fd is broken~%" fd)
  (let* ([host (hashtable-ref fds fd #f)]
         [newregfd (filter (lambda (v) (not (= v fd))) (hashtable-ref hosts host '())) ])
    (printf "host: ~a, newregfd: ~a~%" host newregfd)
    (cond ((and (null? newregfd) (not (some (lambda (h) (string=? host h)) sendbroken)))
      (printf "~a has no more fd, put in host list to reopen~%" host) 
      (set! sendbroken (append sendbroken (list host)))))
    (hashtable-set! hosts host newregfd))
  (set! fdrecv (filter (lambda (cfd) (not (= cfd fd))) fdrecv))
  (hashtable-delete! fds fd)
  (hashtable-delete! pristine fd)
  (hashtable-delete! fds-recv-buffer fd)
  (hashtable-delete! fds-send-buffer fd)
  (co-unlock fd)
  (epoll-del epfd fd ev)
  (close fd))

; timers
(define timerl (make-eq-hashtable))
(define (coio-sleep time)
  (let ([tfd (nb-timer time)])
    (assert (not (= tfd -1)))
    (epoll-add epfd tfd '(EPOLLIN EPOLLET) ev)
    (hashtable-set! timerl tfd #t)
    (co-lock tfd)))
  
(define (coio-timer time fx)
  (co-thunk (lambda ()
    (coio-sleep time)
    (fx))))

; handle send here
(define fds-send-buffer (make-eq-hashtable))

(define (encapsulate msg)
  (let* ([mlen (bytevector-length msg)]
         [out (make-bytevector (+ 2 mlen))])
    (assert (< (+ mlen 2) (expt 2 16)))
    (bytevector-u16-set! out 0 (+ 2 mlen) 'little)
    (bytevector-copy! msg 0 out 2 mlen)
    out))

(define (send-buff fd)
  (let ([buff (hashtable-ref fds-send-buffer fd #f)])
    (cond 
      ((not buff) #t)
      (#t
        (let ([r (send fd buff (bytevector-length buff) 'MSG_DEFAULT)])
          (case (iostatus r)
           ((not-ready) #t)
           ((fatal) (coio-fd-broken fd))
           ((ok)
             (let* 
               ([remlen (- (bytevector-length buff) r)]
                [rem (make-bytevector remlen)])
              (cond
                ((= remlen 0)
                  (printf "buff sent~%")
                  (hashtable-delete! fds-send-buffer fd)
                  (co-unlock fd))
                (#t
                  (bytevector-copy! buff r rem 0 remlen)
                  (hashtable-set! fds-send-buffer fd rem)
                  (send-buff fd)))))))))))
        
(define (coio-congestion dest)
  (let ([fd (hashtable-ref hosts (aget 'host dest) '())])
    (cond
      ((null? fd) +inf.0)
      (#t
        (bytevector-length
          (hashtable-ref 
            fds-send-buffer 
            (car fd) 
            #vu8()))))))
          

(define (coio-send dest msg)
  (let* ([fd (hashtable-ref hosts (aget 'host dest) '())]
         [out (encapsulate msg)])
    (cond
      ((null? fd)
        (cond
          ((some (lambda (v) (string=? (aget 'host dest) v)) sendbroken)
            #f)
          (#t 
            (coio-connect dest) 
            (coio-send dest msg))))
      ((hashtable-ref fds-send-buffer (car fd) #f) 
        (co-lock (car fd))
        (coio-send dest msg))
      (#t 
        (printf "buff scheduled ~%")
        (hashtable-set! fds-send-buffer (car fd) out)
        (send-buff (car fd))))))

; handle recv here
(define coiobv (make-bytevector (expt 2 16)))
(define fds-recv-buffer (make-eq-hashtable))

(define (coio-recv) 
  (cond
    ((null? fdrecv) (co-lock 'recv) (coio-recv))
    (#t
      (let* ([fd (car fdrecv)]
             [msg (hashtable-ref fds-recv-buffer fd #f)]
             [client (hashtable-ref fds fd #f)])
        (assert (and msg (eq? 'full (car msg))))
        (assert client)
        (set! fdrecv (cdr fdrecv))
        (hashtable-delete! fds-recv-buffer fd)
        (read-buff fd)
        (values `((host . ,client) (idx . ,(ip->idx client))) (cadr msg))
))))

(define (chunk-read fd len)
  (let* ([r (recv fd coiobv len 'MSG_DEFAULT)]
         [bv (make-bytevector (max r 0))])
    (bytevector-copy! coiobv 0 bv 0 (bytevector-length bv))
    (values (iostatus r) r bv)))

(define (nfo-remaining nfo)
  (cond 
    ((null? (cdr nfo)) 2)
    (#t
      (-
       (bytevector-u16-ref (cadr nfo) 0 'little)
       (fold-left (lambda (acc v) (+ acc (bytevector-length v))) 0 (cdr nfo))))))

(define (nfo-aggregate nfo)
  (let ([res (make-bytevector (- (bytevector-u16-ref (cadr nfo) 0 'little) 2))])
    (fold-left 
      (lambda (ptr v) 
        (bytevector-copy! v 0 res ptr (bytevector-length v))
        (+ ptr (bytevector-length v))) 
      0
      (cddr nfo))
    res))

(define (build-nfo fd nfo)
  (cond
    ((eq? 'full (car nfo)) nfo)
    (#t
      (let ([remaining (nfo-remaining nfo)])
        (cond
          ((= remaining 0) 
            (set! fdrecv (cons fd fdrecv))
            (co-unlock 'recv)
            `(full ,(nfo-aggregate nfo)))
          (#t
            (let-values ([(status nread data) (chunk-read fd remaining)])
              (cond
                ((eq? status 'not-ready) nfo)
                ((eq? status 'ok) (build-nfo fd (append nfo (list data))))
                ((eq? status 'fatal) (coio-fd-broken fd) '(filling))))))))))
(define (read-buff fd)
  (hashtable-update!
    fds-recv-buffer
    fd
    (lambda (nfo) (build-nfo fd nfo))
    '(filling)))

; handle main loop here
(define (coio-event-loop host)
  (set! hostaddr host)
  (let*-values 
    ([(epfd2 ev2 events2 max-events2) (epoll-init)]
     [(fd) (nb-listen hostaddr hardcoded-port)]
     [(recofd) (nb-timer 5)])

    (assert (not (or (= fd -1) (= recofd -1))))
    (epoll-add epfd2 fd '(EPOLLIN EPOLLET) ev2)
    (epoll-add epfd2 recofd '(EPOLLIN EPOLLET) ev2)
    (set! listen-sock fd)
    (set! reco-sock recofd)
    (set! epfd epfd2)
    (set! ev ev2)
    (set! events events2)
    (set! max-events max-events2))

  (co-thunk (lambda () 
    (let f ()
      (co-flush) ; exhaust all coroutines before looping
      (for-each 
        (lambda (evt)
          ;(printf "evt: ~a~%" evt)
          (cond
            ((epoll-evt? evt '(EPOLLRDHUP EPOLLHUP EPOLLERR))
              (coio-fd-broken (car evt)))

            ; accept connections
            ((= (car evt) listen-sock) 
              (assert (epoll-evt? evt 'EPOLLIN))
              (coio-accept (car evt)))

            ; restart connections
            ((= (car evt) reco-sock)
             (nb-timer-ack (car evt))
             (coio-reconnect))
 
            ; handle timers
            ((hashtable-ref timerl (car evt) #f)
              (hashtable-delete! timerl (car evt))
              (close (car evt))
              (co-unlock (car evt)))

            ; handle IO
            ((epoll-evt? evt 'EPOLLIN)
              (if (hashtable-ref pristine (car evt) #f) (coio-handle-pristine (car evt)))
              (read-buff (car evt)))

            ((epoll-evt? evt 'EPOLLOUT)
              (if (hashtable-ref pristine (car evt) #f) (coio-handle-pristine (car evt)))
              (send-buff (car evt)))
        ))
        (epoll-wait epfd events max-events -1))
      (f)))))
