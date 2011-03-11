require File.dirname(__FILE__) + '/test_helper.rb'
include ScheRuby

class TestScheRuby < Test::Unit::TestCase

  def setup
  end
  
  def test_sicp_sqrt

    code =<<EOF
(define (sqrt x)
  (define (square x) (* x x))
  (define (average x y) (/ (+ x y) 2))
  (define (good-enough? guess)
    (< (abs (- (square guess) x)) 0.001))
  (define (improve guess)
    (average guess (/ x guess)))
  (define (sqrt-iter guess)
    (if (good-enough? guess)
        guess
        (sqrt-iter (improve guess))))
  (sqrt-iter 1.0))
  (sqrt 100000000))
EOF

  env_frame = EnvFrame.new
  assert_equal 10000.0, ScheRuby.scheme!(code)

  end

  def test_version_of_sicp_sqrt_using_send
    code =<<EOF
    (define (sqrt x)
  (define (square x) (.send x "**" 2))
  (define (average x y) (.quo (.send x "+" y) 2))
  (define (goodenough guess)
    (.send (.abs (.send (square guess) "-"  x)) "<" 0.00001))
  (define (improve guess)
    (average guess (.quo x guess)))
  (define (sqrtiter guess)
    (if (goodenough guess)
        guess
        (sqrtiter (improve guess))))
  (sqrtiter 1.0))
(define val 100000000)
(sqrt val)
EOF

  env_frame = EnvFrame.new
  assert_equal 10000.0, ScheRuby.scheme!(code)

  end
    
  def test_entire_table
    TEST_TABLE.each do |record|
      retval = nil
      assert_nothing_raised(record[2]) do
        env_frame = EnvFrame.new
        retval = ScheRuby.scheme!(record[0])
      end
      assert_equal record[1], retval, record[2]
    end
  end
  
  TEST_TABLE = [
# Format is:
# Code                                 , Expected                             , [Optional Comment]         
[ '3'     ,        3 ,    'literal'],
[ ' 3 '     ,        3 ,    'literal with whitespace'],
[ '3 4 5',       5,' multiple literals should return lasts eval'],
[ '#t',             true, 'bool literal'],
[ '#nil',             nil, 'Rubys nil literal'],
[ '"Hello"',            "Hello", 'string literal' ],
[ ' "Using quotation marks(\")" ',  'Using quotation marks(")', 'string literals with escaped quotes'],
["
3 ; should be ignored since it's a comment ' ! ! ! (define
; and so should this ( define
4", 4, 'comments'],

['(if 3 4 5)', 4, 'if true'],
['(if #f 4 5)', 5, 'if false'],
['(if #nil 4 5)', 5, 'if nil'],
['(if #f 1) 100', 100, 'if can lack an alternate clause - evaluation result is unspecified'],


['((lambda () 3))', 3, 'nullary lambda'],
['((lambda (x) 3) 10)', 3, 'unary lambda'],
['((lambda (x) x) 10)', 10, 'unary lambda handles arg properly'],
["((lambda (x y z)   ((lambda (x)      (if x x y)) z)) #f 4 5)", 5, 'Nested lambdas override scope, and inherit when not overriding'],
['(define x 1) (define x 2) (lambda () (define x 3) 5) x', 2, 'More lambdas and defines'],
['(define x 1) (define x 2) ((lambda () (define x 3) 5))', 5, 'More lambdas and defines'],

['(define x 3) x', 3, 'define'],
['(define x 3) (define x 4) x', 4, 'define can override'],
['(define x 3) ((lambda () x))', 3, 'define is accessible from lambdas'],
['(define x 3) ((lambda (x) x) 4))', 4, 'define from within lambda'],
['(define x 3) ((lambda (x) x) 4) x', 3, 'define in lambdas does not override container'],
['(define (xory x y) (if x x y)) (xory #f 10)', 10, 'define lambda shortcut'],
['(define (f x)
  (define (g x)
    (* x x))
  (/ (g x) 2))
(f 3)', 9.quo(2), 'nested define'],

['(+ 10 100 1000)', 1110, '+'],
['(- 10 100 1000)', -1090, '-'],
['(* 1 2 3 4 5)', 120, '*'],
['(/ 1 2 3)', 1.quo(6), '/'],
['(= 1 1 1)', true, '= true'],
['(= 1 1 2)', false, '= false'],

["(+ 0.3 -1.2 0xa 5)", 14.1, 'different types of numeric literals' ],

['(.abs 100)', 100, 'Rubys #abs'],
['(.downcase "aBcD") ', 'abcd', 'Rubys #downcase'],
['(.include? "aBcD" "B") ', true, 'Rubys #include? (method with arg)'],
['(.include? "aBcD" "x") ', false, 'Rubys #include? (method with arg)'],
['(define plus (lambda (a b) (.send a "+" b))) (plus 3 4)', 7, 'Rubys #send'],

["(cond ((> 3 2) 'greater) ((<3 2)) 'less)", :greater, 'cond'],
["(cond ((> 3 3) 'greater) ((< 3 3) 'less) (else 'equal))", :equal, 'cond with else'],

['(car (list 4 5 6))', 4, 'car and list'],
['(car (cdr (list 4 5 6)))', 5, 'car cdr and list'],
['(cdr (cons 3 4))', 4, 'cons and cdr'],

[" 'thisisasymbol ", :thisisasymbol, 'quoting a symbol'],
[ " 'aaa ", :aaa, 'symbol'],
[ " 'a1 ", :a1, 'symbol with digit'],
[ " '.a ", ".a".to_sym, 'symbol with leading dot'],
["(car '(3 4 5))", 3, 'quoting'],
["( car (cdr '(3 4 5)) )", 4, 'quoting'],

# For now, we only support 2 arg append
#['(null? (append))', true, 'append nothing'],
#["(car (append '(3 4)))", 3, 'append 1 list'],
["(car (cdr (append '(3) '(4 5))))", 4, 'append 2 lists'],
#["(car (cdr (cdr (append '(3) '(4 5) '(6 7)))))", 6, 'append 3 lists'],

["(and (list? '()) (not (pair? '())))", true, 'the empty list is a list but not a pair'],
["(and (list? '(3)) (pair? '(3)))", true, '(3) is a list and a pair'],
["(and (list? '(3 4 5)) (pair? '(3 4 5)))", true, '(3 4 5) is a list and a pair'],
["(and (not (list? (cons 3 4))) (pair? (cons 3 4)))", true, 'pairs can be pairs but not lists'],

["(let ((x 3) (y 2)) (+ x y))", 5, 'let'],

["(define x '(1 2)) (set-car! x 10) (car x)", 10, 'set-car!'],
["(define x '(1 2)) (set-car! x 10) (car (cdr x))", 2, "set-car! doesn't touch cdr"],
["(define x (cons 1 2)) (set-cdr! x 10) (cdr x)", 10, 'set-cdr!'],
["(define x '(1 2)) (set-cdr! x 10) (car x)", 1, "set-cdr! doesn't touch car"],

["
(define (map fn lst) (if (null? lst) lst (cons (fn (car lst)) (map fn (cdr lst)))))
(car (cdr (map (lambda (x) (* x x)) (list 3 4 5 6))))
", 16, 'map on list'],
["
  (define (etmap efn tfn lst)
  (cond ((null? lst) lst)
        ((null? (cdr lst)) (cons (tfn (car lst)) '()))
        (else (cons (efn (car lst)) (etmap efn tfn (cdr lst))))))

(inspect (etmap (lambda (x) (* x x)) (lambda (x) (+ x 1)) (list 1 2 3 4 5)))
", "(1 4 9 16 6)", 'etmap'],

["(define x 'a) (set! x 'b) x", :b, 'set!'],
["(define x #f) (set! x #nil) x", nil, 'set! on false and nil'],
["(define x 0) (define (modx) (set! x (+ 1 x))) (modx) (modx) x", 2, 'set! from procedures'],

["(define (fib n)
  (cond ((= n 0) 0)
        ((= n 1) 1)
        (else (+ (fib (- n 1))
                 (fib (- n 2)))))) 
   (fib 7)", 13, 'sicp recursive fib'],
                 
["(define (fib n)
  (fib-iter 1 0 n))

(define (fib-iter a b count)
  (if (= count 0)
      b
      (fib-iter (+ a b) a (- count 1))))
  (fib 7)", 13, 'sicp iterative fib'],

["(define (count-change amount)
  (cc amount 5))
(define (cc amount kinds-of-coins)
  (cond ((= amount 0) 1)
        ((or (< amount 0) (= kinds-of-coins 0)) 0)
        (else (+ (cc amount
                     (- kinds-of-coins 1))
                 (cc (- amount
                        (first-denomination kinds-of-coins))
                     kinds-of-coins)))))
(define (first-denomination kinds-of-coins)
  (cond ((= kinds-of-coins 1) 1)
        ((= kinds-of-coins 2) 5)
        ((= kinds-of-coins 3) 10)
        ((= kinds-of-coins 4) 25)
        ((= kinds-of-coins 5) 50)))

 (count-change 20)
        ", 9, 'sicp count-change recursion'],


["
(define dx 0.0000000000001)

(define (deriv g)
  (lambda (x)
    (/ (- (g (+ x dx)) (g x))
       dx)))

(define (square x) (* x x))

(< (abs (- ((deriv square) 2) 4)) 0.01 )
", true, 'sicp HOF'],


["

(define dx 0.00001)

(define (deriv g)
  (lambda (x)
    (/ (- (g (+ x dx)) (g x))
       dx)))

(define (average x y) (/ (+ x y) 2))

(define (average-damp f)
  (lambda (x) (average x (f x))))
  
(define tolerance 0.001)

(define (fixed-point f first-guess)
  (define (close-enough? v1 v2)
    (< (abs (- v1 v2)) tolerance))
  (define (try guess)
    (let ((next (f guess)))
      (if (close-enough? guess next)
          next
          (try next))))
  (try first-guess))

(define (sqrt x) (fixed-point (average-damp (lambda (g) (/ x g))) 2.0))

(< (abs (- (sqrt 2) 1.41421)) tolerance)
  
", true, 'sicp newtons method'],

[
"(define (scale-tree tree factor)
  (cond ((null? tree) '())
        ((not (pair? tree)) (* tree factor))
        (else (cons (scale-tree (car tree) factor)
                    (scale-tree (cdr tree) factor)))))
( car (car ( cdr (scale-tree (list 1 (list 2 (list 3 4) 5) (list 6 7)) 10))))                    
", 20, 'sicp scale-tree (pairs)'
],

["
(define floor .floor)

(define (make-oracle secret)
  (lambda (query-proc)
    (if (query-proc secret) #t #f)))

(define (mb-search oracle greater-than less-or-equal-to)
  (define greater-or-equal-to (+ 1 greater-than))
  
  (define (make-is-greater-than-query val)
    (lambda (secret) (> secret val)))
  
  (cond ((= less-or-equal-to greater-or-equal-to) less-or-equal-to)
        ((< less-or-equal-to greater-or-equal-to) 'no-solution-found)
        (else (let ((mid-point (floor (/ (+ greater-than less-or-equal-to) 2))))
               (if (oracle (make-is-greater-than-query mid-point))
                   (mb-search oracle mid-point less-or-equal-to)
                   (mb-search oracle greater-than mid-point))))))

 (mb-search (make-oracle 15335353) 0 100000000000000000000)
", 15335353, "oracle/query modified binary search code"],

["(define x 0) (begin (set! x 5) (+ x 1))", 6, 'begin'],

["Kernel", Kernel, 'Ruby class'],
["::Kernel", Kernel, 'Ruby class with colon'],
["(if RUBY_PLATFORM #t #f)", true, 'Ruby constant'],
["(if ::RUBY_PLATFORM #t #f)", true, 'Ruby constant with colon'],
["(inspect (new Array))", "[]", 'Instantiate a Ruby class'],
["(define a (new Array)) (hash-set! a 0 (* 2 5))  (hash-set! a 1 (* 1 5)) (hash-get a 0)", 10, 'hash-get and hash-set!'],

["(defconstant A 3) A", 3, 'defconstant'],
["(defconstant B (+ 1 4)) B", 5, 'defconstant evaluates'],
["(define x 10) (defconstant C (+ 1 x)) C", 11, 'defconstant and scope'],

["(define anon-class (new Class))
(.define_method anon-class 'dummy_method (lambda () 'dummy))
(define an-instance (new anon-class))
(inspect an-instance)
(inspect (.method an-instance 'dummy_method))
(inspect (lambda () 'dummy))
(.dummy_method an-instance)
", :dummy, "Defining Ruby classes and methods"],
["(define anon-class (new Class))
(defmethod anon-class 'dummy_method (lambda () 'dummy))
(define an-instance (new anon-class))
(inspect an-instance)
(inspect (.method an-instance 'dummy_method))
(inspect (lambda () 'dummy))
(.dummy_method an-instance)
", :dummy, "Defining Ruby classes and methods - defmethod works also"],
["
(defconstant MyClass (new Class))
(inspect MyClass)
(.define-method MyClass 'to-upper (lambda (str) (.upcase str)))
(.to-upper (new MyClass) \"hello\")
", 'HELLO', "Giving classes names using defconstant"
],
["(.superclass (new Class Array))", Array, 'superclass'],
["(defconstant SillyClass (new Class))
(defmethod SillyClass 'set-qty! (lambda (qty) (set-ivar! @qty qty)))
(defmethod SillyClass 'get-qty (lambda () @qty))
(define a (new SillyClass))
(.set-qty! a 70)
(define b (new SillyClass))
(.set-qty! b 30)
(define c (new SillyClass))
(.set-qty! c 1000)
(+ (.get-qty a) (.get-qty b))
", 100, 'instance variables'],
["
(defconstant BeanCounter (new Class))

(defmethod BeanCounter 'count! (lambda ()
  (set-ivar! @qty (+ 1 (if @qty @qty 0)))))

(defmethod BeanCounter 'repeat-count! (lambda (times)
  (if (> times 0) (begin (.count! self) (.repeat-count! self (- times 1))))))

(defmethod BeanCounter 'get-count (lambda ()
  @qty))
  
(defmethod BeanCounter 'higher_than? (lambda (minimum)
  (>= (.get-count self) minimum)))
  
(define bc1 (new BeanCounter))
(.repeat-count! bc1 10)
(define bc2 (new BeanCounter))
(.repeat-count! bc2 3)
(.higher_than? bc1 6)
", true, 'methods invoking other methods via self'],


["
(define v (make-vector 10))
(vector-set! v 3 100)
'dummy
(vector-ref v 3)
", 100, 'vector'],

['
(define adder (.eval self "Proc.new { |a,b| a + b}"))
(define (invoke fn x y)
  (fn x y))
(invoke adder 3 4)
', 7, 'Ruby Procs as lambdas'],

['
(define (square x) (* x x))
(.call square 3)
', 9, 'lambdas as Ruby Procs'],


]


end
