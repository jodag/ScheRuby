; Benchmark based on http://schemekeys.blogspot.com/2007/06/flatten-benchmark-results_25.html

(define abc '(a (b (c (d (e (f (g (h (i (j (k (l (m n) o) p) q) r) s) t) u) v) w) x) y) z))
(define flat '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26))
(define flat-abc '(a b c d e f g h i j k l m n o p q r s t u v w x y z))
(define tree '(a (b (d (i q r) (j s t)) (f (k u v) (l w x))) (c (g (m y z) (n aa bb)) (h (o cc dd) (p ee ff)))))

(define flatten-with-accumulator
  (lambda (slst symbols-so-far)
    (if (null? slst)
        symbols-so-far
        (flatten-sym-expr
         (car slst)
         (flatten-with-accumulator 
           (cdr slst) symbols-so-far)))))

(define flatten-sym-expr
  (lambda (sym-expr symbols-so-far)
    (if (pair? sym-expr)
        (flatten-with-accumulator 
          sym-expr symbols-so-far)
        (cons sym-expr symbols-so-far))))

(define flatten-Eugene
  (lambda (slst)
    (flatten-with-accumulator slst '())))

(define l (cons abc flat))
(define ll (cons l tree))
(define lll (cons ll flat-abc))
(define llll (cons tree lll))
(define lllll (cons llll llll))
(define llllll (cons abc lllll))
(define lllllll (cons lllll lllll))

(define (repeat proc n)
  (if (> n 1)
      (begin (proc) (repeat proc (- n 1))))
      (proc))

(define (flatten-accum-cons-sans-reverse xxs)
  (define (f xxs result)
    (cond
      ((null? xxs) result)
      ((pair? (car xxs)) 
        (f (cdr xxs) (f (car xxs) result)))
      (else (f (cdr xxs) 
        (cons (car xxs) result)))))
  (f xxs '()))

(define p1 (lambda ()(flatten-Eugene lllllll)))
(define p2 (lambda ()(flatten-accum-cons-sans-reverse lllllll)))

(display "flatten #1")
(time (repeat p1 10))
(display "flatten #2")
(time (repeat p2 10))
; Run them again, to confirm stability - the times should match up
(display "flatten #1")
(time (repeat p1 10))
(display "flatten #2")
(time (repeat p2 10))
