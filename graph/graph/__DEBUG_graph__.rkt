#lang debug typed/racket

(require (submod "graph3.lp2.rkt" test))
(require "../lib/low.rkt")
(require racket/list)

(define #:∀ (A) (map-force [l : (Listof (Promise A))])
  (map (inst force A) l))

(let ()
  (map-force (second g))
  (cars (map-force (second g)))
  (map-force (third g))
  (map-force (append* (cars (cdrs (cdrs (map-force (second g)))))))
  (void))

#|
#R(map-force (second g))
#R(map-force (third g))

(newline)

#R(force (car (second g)))
#R(force (cadr (force (car (caddr (force (car (second g))))))))

(newline)
;|#

(define (forceall [fuel : Integer] [x : Any]) : Any
  (if (> fuel 0)
      (cond [(list? x) (map (curry forceall fuel) x)]
            [(promise? x) (forceall (sub1 fuel) (force x))]
            [else x])
      x))

(forceall 5 g)