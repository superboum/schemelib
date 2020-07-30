(define epfd #f)
(define ev #f)
(define events #f)
(define max-events #f)
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
  (let* ([a (nb-accept fd)] [s (iostatus (car a))])
    (case s
      ((fatal) (perror "errno") (raise "we should not fail accept()"))
      ((not-ready) #t)
      ((ok)
        ;(printf "[coio-accept] ~a -> ~a:~a = fd ~a~%" hostaddr (cadr a) (caddr a) (car a))
        (coio-fd-register a) 
        (coio-accept fd)))))

(define (coio-connect dest)
  (cond
    ((not (null? (hashtable-ref hosts (aget 'host dest) '()))) #t)
    (#t
      (let* ([r (nb-connect hostaddr (aget 'host dest) hardcoded-port)]
             [err (errno)]
             [rdy (= (cdr r) 0)]
             [prog (and (= (cdr r) -1) (= err (errno->int 'EINPROGRESS)))])
        ;(printf "[coio-connect] ~a -> ~a:~a = fd ~a~%" hostaddr (aget 'host dest) hardcoded-port r)
        (cond
          ((or rdy prog) (coio-fd-register `(,(car r) ,(aget 'host dest))))
          (#t (perror "failed to connect") (raise "unsupported error")))
       ))))

(define (coio-fd-register client)
  (hashtable-set! pristine (car client) #t)
  (hashtable-set! fds (car client) (cadr client))
  (hashtable-update! hosts (cadr client) (lambda (v) (cons (car client) v)) '())
  (epoll-add epfd (car client) '(EPOLLRDHUP EPOLLIN EPOLLOUT EPOLLET) ev)
  (car client))

(define (coio-handle-pristine fd)
  (hashtable-delete! pristine fd)
  (set! connectready (cons fd connectready))
  (printf "handlepri: ~a~%" connectready)
  (co-unlock 'connectready))

(define (coio-ready)
  ;(printf "loop: ~a~%" connectready)
  (cond
    ((null? connectready) (co-lock 'connectready 'low) (coio-ready))
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
  (hashtable-delete! fds fd)
  (hashtable-delete! pristine fd)
  (hashtable-delete! fds-recv-buffer fd)
  (hashtable-delete! fds-send-buffer fd)
  (set! epollfdtoread (filter (lambda (v) (not (= v fd))) epollfdtoread))
  (set! epollfdtosend (filter (lambda (v) (not (= v fd))) epollfdtosend))
  (co-unlock fd)
  (epoll-del epfd fd ev)
  (close fd))

; timers
(define (coio-sleep time)
  (cond
    ((<= time 0) #t)
    (#t
      (co-lock 'timers 'low)
      (coio-sleep (- time 1)))))

(define coiotimerid 0)
(define (get-coio-timer-id)
  (set! coiotimerid (+ coiotimerid 1))
  coiotimerid)
(define coiotimercb (make-eq-hashtable))
(define (coio-timer time fx)
  (let ([thistimer (get-coio-timer-id)])
    (hashtable-set! coiotimercb thistimer fx)
    (co-thunk
      (lambda ()
        (let f ([rem time])
          (cond
            ((not (hashtable-ref coiotimercb thistimer #f))
              ;(printf "timer ~a deleted~%" thistimer)
              (co-end))
            ((<= rem 0)
              ;(printf "timer ~a expired without being deleted~%" thistimer)
              ((hashtable-ref coiotimercb thistimer "this str should never be returned"))
              (hashtable-delete! coiotimercb thistimer)
               (co-end))
           (#t
              ;(printf "timer ~a ticking (~a)~%" thistimer rem)
              (co-lock 'timers 'low)
              (f (- rem 1)))))))
    thistimer))

(define (coio-timer-cancel thistimer) 
  ;(printf "timer cancelled ~a~%" thistimer)
  (hashtable-delete! coiotimercb thistimer))


; handle send here
(define fds-send-buffer (make-eq-hashtable))

(define (encapsulate msg)
  (let* ([mlen (bytevector-length msg)]
         [out (make-bytevector (+ 2 mlen))])
    (assert (< (+ mlen 2) (expt 2 16)))
    (bytevector-u16-set! out 0 (+ 2 mlen) 'little)
    (bytevector-copy! msg 0 out 2 mlen)
    out))

(define (send-buff-multiplex)
  (if
    (some (lambda (fd) (send-buff fd)) (vector->list (hashtable-keys fds-send-buffer)))
    (send-buff-multiplex)))

(define (send-buff fd)
  (let ([buff (hashtable-ref fds-send-buffer fd '())])
    (cond 
      ((null? buff) #f) ; can't send
      (#t
        (let ([r (send fd (car buff) (bytevector-length (car buff)) 'MSG_DEFAULT)])
          (case (iostatus r)
           ((not-ready) #f) ; can't send
           ((fatal) (coio-fd-broken fd))
           ((ok)
             ;(printf "sent ~a bytes to ~a fd~%" r fd)
             (let* 
               ([remlen (- (bytevector-length (car buff)) r)]
                [rem (make-bytevector remlen)])
              (cond
                ((= remlen 0)
                  (cond
                    ((null? (cdr buff))
                      (hashtable-delete! fds-send-buffer fd)
                      #f) ; can't send anymore
                    (#t
                      (hashtable-update! fds-send-buffer fd (lambda (lout) (cdr lout)) '())
                      #t))) ; still some data to send
                (#t
                  (bytevector-copy! (car buff) r rem 0 remlen)
                  (hashtable-update! fds-send-buffer fd (lambda (lout) (cons rem (cdr lout))) '())
                  #t)))))))))) ; still some data to send
        
(define (coio-congestion dest)
  (let ([fd (hashtable-ref hosts (aget 'host dest) '())])
    (cond
      ((null? fd) +inf.0)
      (#t
        (length (hashtable-ref fds-send-buffer (car fd) '()))))))
          

(define (coio-send dest msg prio)
  ;(printf "sent a message~%") 
  (co-pause)
  (let* ([fd (hashtable-ref hosts (aget 'host dest) '())]
         [out (encapsulate msg)])
    (cond
      ((null? fd)
        (cond
          ((some (lambda (v) (string=? (aget 'host dest) v)) sendbroken)
            #f)
          (#t 
            (coio-connect dest) 
            (coio-send dest msg prio))))
      ((and (not (null? (hashtable-ref fds-send-buffer (car fd) '()))) (eq? prio 'low))
        (printf "send lock app ~a~%" (car fd))
        (co-lock 'epoll prio)
        (coio-send dest msg prio))
      ((not (less-than (hashtable-ref fds-send-buffer (car fd) '()) 50))
        (printf "send lock relay ~a~%" (car fd))
        (co-lock 'epoll prio)
        (coio-send dest msg prio))
      (#t 
        ;(printf "~a will send ~a bytes to ~a (fd ~a)~%" hostaddr (bytevector-length out) (aget 'host dest) (car fd))
        (hashtable-update! fds-send-buffer (car fd) (lambda (lout) (append lout (list out))) '())
        (send-buff-multiplex)))))

; handle recv here
(define coiobv (make-bytevector (expt 2 16)))
(define fds-recv-buffer (make-eq-hashtable))

(define (last-from-list l)
  (let lfl ([liter l] [newl '()])
    (cond
      ((null? liter) (values #f #f))
      ((null? (cdr liter)) (values (car liter) (reverse newl)))
      (#t (lfl (cdr liter) (cons (car liter) newl))))))

(define (nfo-pick fd)
  (let-values ([(msg rest) (last-from-list (hashtable-ref fds-recv-buffer fd '()))])
    (cond
      ((not msg) #f)
      ((eq? (car msg) 'filling) #f)
      (#t
        (hashtable-set! fds-recv-buffer fd (if (null? rest) '((filling)) rest))
        ;(printf "new nfo (pick): ~a~%" rest)
        msg))))


(define (coio-recv)
  (co-pause)
  (let*-values ([(fd msg) (read-buff-multiplex)]
                [(client) (hashtable-ref fds fd hostaddr)])
    (cond
      ((not fd) (co-lock 'epoll 'low) (coio-recv))
      (#t 
        ;(printf "returned a message~%") 
        (values `((host . ,client) (idx . ,(ip->idx client))) msg)))))

(define (chunk-read fd len)
  (let* ([r (recv fd coiobv len 'MSG_DEFAULT)]
         [bv (make-bytevector (max r 0))])
    ;(printf "~a read ~a bytes (~a) from ~a (~a fd)~%" hostaddr r (iostatus r) (hashtable-ref fds fd #f)  fd)
    (bytevector-copy! coiobv 0 bv 0 (bytevector-length bv))
    (values (iostatus r) r bv)))

(define (nfo-remaining nfo)
  (cond 
    ((null? nfo) 2)
    ((and (null? (cdr nfo)) (< (bytevector-length (car nfo)) 2)) 1)
    (#t
      (-
       (bytevector-u16-ref (car nfo) 0 'little)
       (fold-left (lambda (acc v) (+ acc (bytevector-length v))) 0 nfo)))))

(define (nfo-aggregate nfo)
  (let ([res (make-bytevector (- (bytevector-u16-ref (car nfo) 0 'little) 2))])
    (fold-left 
      (lambda (ptr v) 
        (bytevector-copy! v 0 res ptr (bytevector-length v))
        (+ ptr (bytevector-length v))) 
      0
      (cdr nfo))
    res))

(define read-queue '())
(define (read-buff-multiplex)
  (cond
    ((null? read-queue) (values #f #f)) ; exhausted
    (#t 
      (let* ([fd (car read-queue)]
             [pkt (read-buff fd)])
        (cond
          (pkt 
             (set! read-queue (append (cdr read-queue) (list (car read-queue))))
             (values fd pkt))
          (#t
            (set! read-queue (cdr read-queue))
            (read-buff-multiplex)))))))

(define (read-buff fd)
  (let* ([nfo (hashtable-ref fds-recv-buffer fd '())] [remaining (nfo-remaining nfo)])
    (cond
      ((= remaining 0) 
        (hashtable-delete! fds-recv-buffer fd)
        ; here we have a new packet for our very special user <3
        (nfo-aggregate nfo))
      (#t
        (let-values ([(status nread data) (chunk-read fd remaining)])
          (cond
            ((or (eq? status 'not-ready) (= nread 0))  
              ; we exhauted a file descriptor, we can stop watching it, hourra!
              #f)
            ((eq? status 'ok) 
              (hashtable-set! 
                fds-recv-buffer 
                fd 
                (append nfo (list data)))
              ; we can't take any decision here, restarting the process
              (read-buff fd))
            ((eq? status 'fatal) 
              (coio-fd-broken fd) 
              ; here we did not read anything
              #f)))))))

(define (coio-reco-loop)
  (coio-timer 
    10 
    (lambda () 
      (coio-reconnect) 
      (coio-reco-loop))))

; handle main loop here
(define epollfdtoread '())
(define epollfdtosend '())
(define (coio-event-loop host)
  (set! hostaddr host)
  (let*-values 
    ([(epfd2 ev2 events2 max-events2) (epoll-init)]
     [(fd) (nb-listen hostaddr hardcoded-port)]
     [(recofd) (nb-timer 1)])

    (assert (not (or (= fd -1) (= recofd -1))))
    (epoll-add epfd2 fd '(EPOLLIN EPOLLET) ev2)
    (epoll-add epfd2 recofd '(EPOLLIN EPOLLET) ev2)
    (set! listen-sock fd)
    (set! reco-sock recofd)
    (set! epfd epfd2)
    (set! ev ev2)
    (set! events events2)
    (set! max-events max-events2))

  ;(coio-reco-loop)
  (co-thunk (lambda () 
    (let f () 
      (set! read-queue (vector->list (hashtable-keys fds)))
      (co-unlock-all 'epoll)
      (co-flush) ; exhaust all coroutines before looping
      ;(for-each (lambda (ffd) (send-buff ffd)) (vector->list (hashtable-keys fds)))
      ;(printf "tosend: ~a~%" (hashtable-keys fds-send-buffer))
      ;(printf "recv: ~a~%" (hashtable-values fds-recv-buffer))
      ;(printf "locked: ~a~%" (hashtable-keys locked))
      ;(printf "epoll~%")

      ;(set! epollfdtoread '())
      ;(set! epollfdtosend '())
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

            ; the general timer that handle all timers
            ((= (car evt) reco-sock)
             (nb-timer-ack (car evt))
             (co-unlock-all 'timers))

            ; handle IO
            ;(#t
              ;(cond ((epoll-evt? evt 'EPOLLIN)
                ;(set! epollfdtoread (append epollfdtoread (list (car evt))))
                ;(co-unlock-all (car evt))))
 
              ;(cond ((epoll-evt? evt 'EPOLLOUT)
                ;(set! (append epollfdtosend (list (car evt))))
                ;(co-unlock-all (car evt)))))
        ))
        (epoll-wait epfd events max-events -1))
      (f)))))
