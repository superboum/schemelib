; RFC6817
; https://tools.ietf.org/html/rfc6817

(define-record-type ledbat-params
  (fields 
    ; The term "MSS", or the sender's Maximum Segment Size, used in this
    ; document refers to the size of the largest segment that the sender
    ; can transmit.  The value of MSS can be based on the path MTU
    ; discovery [RFC4821] algorithm and/or on other factors.
    mss
    ; INIT_CWND and MIN_CWND SHOULD both be 2.  An INIT_CWND of 2 should
    ; help seed FILTER() at the sender when there are no samples at the
    ; beginning of a flow, and a MIN_CWND of 2 allows FILTER() to use more
    ; than a single instantaneous delay estimate while not being too
    ; aggressive.  Slight deviations may be warranted, for example, when
    ; these values of INIT_CWND and MIN_CWND interact poorly with the
    ; framing protocol.  However, INIT_CWND and MIN_CWND MUST be no larger
    ; than the corresponding values specified for TCP [RFC5681].
    init_cwnd 
    min_cwnd 
    ; ALLOWED_INCREASE SHOULD be 1, and it MUST be greater than 0.  An
    ; ALLOWED_INCREASE of 0 results in no cwnd growth at all, and an
    ; ALLOWED_INCREASE of 1 allows and limits the cwnd increase based on
    ; flightsize in the previous RTT.  An ALLOWED_INCREASE greater than 1
    ; MAY be used when interactions between LEDBAT and the framing protocol
    ; provide a clear reason for doing so.
    allowed_increase 
    ;  The size of the base_delays list, BASE_HISTORY, SHOULD be 10.  If the
    ; actual base delay decreases, due to a route change, for instance, a
    ; LEDBAT sender adapts immediately, irrespective of the value of
    ; BASE_HISTORY.  If the actual base delay increases, however, a LEDBAT
    ; sender will take BASE_HISTORY minutes to adapt and may wrongly infer
    ; a little more extra delay than intended (TARGET) in the meanwhile.  A
    ; value for BASE_HISTORY is thus a trade-off: a higher value may yield
    ; a more accurate measurement when the base delay is unchanging, and a
    ; lower value results in a quicker response to actual increase in base
    ; delay.
    base_history
    ; GAIN MUST be set to 1 or less.  A GAIN of 1 limits the maximum cwnd
    ; ramp-up to the same rate as TCP Reno in Congestion Avoidance.  While
    ; this document specifies the use of the same GAIN for both cwnd
    ; increase (when off_target is greater than zero) and decrease (when
    ; off_target is less than zero), implementations MAY use a higher GAIN
    ; for cwnd decrease than for the increase; our justification follows.
    gain 
    ; TARGET MUST be 100 milliseconds or less, and this choice of value is
    ; explained further in Section 3.3.  Note that using the same TARGET
    ; value across LEDBAT flows enables equitable sharing of the bottleneck
    ; bandwidth.  A flow with a higher TARGET value than other competing
    ; LEDBAT flows may get a larger share of the bottleneck bandwidth.  It
    ; is possible to consider the use of different TARGET values for
    ; implementing a relative priority between two competing LEDBAT flows
    ; by setting a higher TARGET value for the higher-priority flow.
    target
    ; The size of this list, CURRENT_FILTER,
    ; may be variable, and it depends on the FILTER() function as well as
    ; the number of successful measurements made within an RTT amount of
    ; time in the past.  The sender should seek to gather enough delay
    ; samples in each RTT so as to have statistical confidence in the
    ; measurements.  While the number of delay samples required for such
    ; confidence will vary depending on network conditions, the sender
    ; SHOULD use at least 4 delay samples in each RTT, unless the number of
    ; samples is lower due to a small congestion window.  The value of
    ; CURRENT_FILTER will depend on the filter being employed, but
    ; CURRENT_FILTER MUST be limited such that samples in the list are not
    ; older than an RTT in the past.
    current_filter))

(define-record-type ledbat-state
  (fields current_delays base_delays last_rollover flightsize cwnd cto))

(define (ledbat-params-default)
  (make-ledbat-params 
    1498 ; mss
    2 2 ; init_cwnd min_cwnd
    1 ; allowed_increase
    10 ; base_history
    1 ; gain
    100 ; target
    5 ; current_filter
))

;(define (on-init params) 
;  (make-ledbat-state

;(define (on-data) )

;(define (on-ack) )
