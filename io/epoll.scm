; epoll
(define (epoll-env fx)
  (let*
    ([epollfd (epoll_create 1)]
     [max-events 10]
     [ev-ptr (foreign-alloc (ftype-sizeof epoll_event))]
     [ev (make-ftype-pointer epoll_event ev-ptr)]
     [events-ptr (foreign-alloc (* max-events (ftype-sizeof epoll_event)))]
     [events (make-ftype-pointer epoll_event events-ptr)])

  (assert (not (= -1 epollfd)))
  (fx epollfd ev events max-events)
  (foreign-free ev-ptr)
  (foreign-free events-ptr)))

(define (set-ev ev flags fd)
  (ftype-set! epoll_event (events) ev (epoll-ev->int flags))
  (ftype-set! epoll_event (data fd) ev fd)
  ev)

(define (epoll-add epfd fd flags ev)
  (assert (= 0 (epoll_ctl epfd 'EPOLL_CTL_ADD fd (set-ev ev flags fd)))))

(define (epoll-wait epfd events max-events time)
  (let ([cnt (epoll_wait epfd events max-events time)])
    (let r ([to-process cnt])
      (cond
        ((= to-process 0) '())
        (#t
          (cons
            `(,(ftype-ref epoll_event (data fd) events (- to-process 1))
              .
              ,(ftype-ref epoll_event (events) events (- to-process 1)))
             (r (- to-process 1)))
)))))

