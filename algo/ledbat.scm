; RFC6817
; https://tools.ietf.org/html/rfc6817

(define-record-type ledbat-params
  (fields 

(define-record-type ledbat-state
  (fields current_delays base_delays last_rollover flightsize cwnd cto))

(define (on-init params) 
  (make-ledbat-state

(define (on-data) )

(define (on-ack) )
