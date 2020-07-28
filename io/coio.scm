(define epfd #f)
(define ev #f)
(define events #f)
(define max-events #f)
(define fdrecv '())
(define listen-sock #f)
(define buffers (make-eq-hashtable))
(define fds (make-eq-hashtable))
(define hosts (make-hashtable string-hash string=?))
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
      (printf "try to recv on ~a~%" (car fdrecv))
      (let ([res (recv (car fdrecv) coiobv (bytevector-length coiobv) 'MSG_DEFAULT)]
            [code (errno)]
            [client (hashtable-ref fds (car fdrecv) #f)])
        (cond
          ((and (= -1 res) (or (= code (errno->int 'EINPROGRESS)) (= code (errno->int 'EAGAIN))))
            (set! fdrecv (cdr fdrecv))
            (coio-recv))
          ((= -1 res) (perror "recv failed") (printf "~a ~a~%" code (errno->int 'EAGAIN)) (raise "Unsupported error"))
          (#t 
            (let ([cbv (make-bytevector res)])
              (bytevector-copy! coiobv 0 cbv 0 res)
              (values client cbv)))
)))))

(define (coio-send dest msg)
  (let ([client (hashtable-ref hosts (aget 'host dest) '())])
    (cond
      ((null? client) #f)
      (#t 
        (let ([r (send (car client) msg (bytevector-length msg) 'MSG_DEFAULT)] [err (errno)])
          (cond
            ((and (= r -1) (= err (errno->int 'EAGAIN))) (co-lock (car client)) (coio-send dest msg))
            ((= r -1)
              (perror "failed to send")
              (coio-fd-broken (car client))
)))))))

(define (coio-connect dest)
  (cond
    ((not (null? (hashtable-ref hosts (aget 'host dest) '()))) #t)
    (#t
      (let* ([r (nb-connect hostaddr (aget 'host dest) hardcoded-port)]
             [err (errno)]
             [rdy (= (cdr r) 0)]
             [prog (and (= (cdr r) -1) (= err (errno->int 'EINPROGRESS)))])
        (cond
          ((or rdy prog)
            (epoll-add epfd (car r) '(EPOLLOUT EPOLLIN EPOLLRDHUP EPOLLET) ev)
            (hashtable-set! fds (car r) (aget 'host dest))
            (hashtable-update! hosts (aget 'host dest) (lambda (v) (cons (car r) v)) '()))
          (#t (perror "failed to connect") (raise "unsupported error")))))))

(define (coio-fd-broken fd)
  (printf "~a fd is broken~%" fd)
  (let* ([host (hashtable-ref fds fd #f)]
         [newregfd (filter (lambda (v) (not (= v fd))) (hashtable-ref hosts host '())) ])
    (printf "host: ~a, newregfd: ~a~%" host newregfd)
    (cond ((null? newregfd) 
      (printf "~a has no more fd, put in host list to reopen~%" host) 
      (set! sendbroken (cons host sendbroken))))
    (hashtable-set! hosts host newregfd))
  (hashtable-delete! fds fd)
  (epoll-del epfd fd ev)
  (close fd)
  (co-unlock fd)
)


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
              (coio-fd-broken (car evt)))

            ; accept connections
            ((= (car evt) listen-sock)
              (assert (epoll-evt? evt 'EPOLLIN))
              (let ([client (nb-accept (car evt))])
                (printf "~a~%" client)
                (hashtable-set! fds (car client) (cadr client))
                (hashtable-update! hosts (cadr client) (lambda (v) (cons (car client) v)) '())
                (epoll-add epfd (car client) '(EPOLLRDHUP EPOLLIN EPOLLOUT EPOLLET) ev)))

            (#t
              (cond ((epoll-evt? evt 'EPOLLIN)
                (printf "~a can recv~%" evt)
                (set! fdrecv (cons (car evt) fdrecv))
                (co-unlock 'recv)))
              (cond
                ((epoll-evt? evt 'EPOLLOUT)
                  (printf "~a can send~%" evt)
                  (co-unlock (car evt))))

        )))
        (epoll-wait epfd events max-events -1))
      (f)))))
