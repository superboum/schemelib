(define epfd #f)
(define ev #f)
(define events #f)
(define max-events #f)
(define fdrecv '())
(define listen-sock #f)
(define buffers (make-eq-hashtable))
(define fds (make-eq-hashtable))
(define sendhash (make-hashtable string-hash string=?))
(define sendbroken '())
(define coiobv (make-bytevector 4096))
(define hostaddr #f)
(define hardcoded-port 3500)

(define (coio-recv) 
  (cond
    ((null? fdrecv) 
      (co-lock 'recv) 
      (coio-recv))
    (#t
      (let ([res (recv (car fdrecv) coiobv (bytevector-length coiobv) 'MSG_DEFAULT)]
            [code (errno)]
            [client (hashtable-ref fds (car fdrecv) #f)])
        (cond
          ((and (= -1 res) (= code (errno->int 'EAGAIN)))
            (set! fdrecv (cdr fdrecv))
            (coio-recv))
          ((= -1 res) (printf "error ~a~%" res) (raise "Unsupported error"))
          (#t 
            (let ([cbv (make-bytevector res)])
              (bytevector-copy! coiobv 0 cbv 0 res)
              (values client cbv)))
)))))

(define (coio-send dest msg)
  (let ([client (hashtable-ref sendhash (aget 'host dest) #f)])
    (cond
      ((not client) #f)
      (#t 
        (let ([r (send client msg (bytevector-length msg) 'MSG_DEFAULT)] [err (errno)])
          (cond
            ((and (= r -1) (= err (errno->int 'EAGAIN))) (co-lock client) (coio-send dest msg))
            ((= r -1)
              (perror "an error occured, rebuild later")
              (epoll-del epfd client ev)
              (close client)
              (hashtable-delete! sendhash (aget 'host dest))
              (set! sendbroken (cons (aget 'host dest) sendbroken))
)))))))

(define (coio-connect dest)
  (cond
    ((hashtable-ref sendhash (aget 'host dest) #f) #t)
    (#t
      (let* ([r (nb-connect hostaddr (aget 'host dest) hardcoded-port)]
             [err (errno)]
             [rdy (= (cdr r) 0)]
             [prog (and (= (cdr r) -1) (= err (errno->int 'EINPROGRESS)))])
        (cond
          ((or rdy prog)
            (epoll-add epfd (car r) '(EPOLLOUT EPOLLET) ev)
            (hashtable-set! fds (car r) (aget 'host dest))
            (hashtable-set! sendhash (aget 'host dest) (car r)))
          (#t (raise "unsupported error")))))))

(define (coio-event-loop host)
  (set! hostaddr host)
  (let*-values 
    ([(epfd2 ev2 events2 max-events2) (epoll-init)]
     [(fd) (nb-listen hostaddr hardcoded-port)])

    (epoll-add epfd2 fd '(EPOLLIN EPOLLET) ev2)
    (set! listen-sock fd)
    (set! epfd epfd2)
    (set! ev ev2)
    (set! events events2)
    (set! max-events max-events2))

  (co-thunk (lambda () 
    (let f ()
      (co-flush) ; exhaust all coroutines before looping
      (for-each 
        (lambda (evt)
          (printf "evt: ~a~%" evt)
          (cond
            ((epoll-evt? evt '(EPOLLRDHUP EPOLLHUP EPOLLERR))
              (let ([host (hashtable-ref fds (car evt) #f)])
                (cond 
                  ((hashtable-ref sendhash host #f)
                    (set! sendbroken (cons host sendbroken))
                    (hashtable-delete! sendhash host))))
              (hashtable-delete! fds (car evt))
              (epoll-del epfd (car evt) ev)
              (close (car evt)))

            ; accept connections
            ((and (epoll-evt? evt 'EPOLLIN) (= (car evt) listen-sock))
              (let ([client (nb-accept (car evt))])
                (hashtable-set! fds (car client) (cadr client))
                (epoll-add epfd (car client) '(EPOLLRDHUP EPOLLIN EPOLLET) ev)))

            ((epoll-evt? evt 'EPOLLIN)
              (set! fdrecv (cons (car evt) fdrecv))
              (co-unlock 'recv))
            ((epoll-evt? evt 'EPOLLOUT)
              (co-unlock (car evt)))

        ))
        (epoll-wait epfd events max-events -1))
      (f)))))
