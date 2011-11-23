(library 
  (ck)

  (export
    ;; framework
    lhs rhs update-s update-c make-a any/var? prefix-s
    lambdam@ identitym composem goal-construct ext-c
    build-oc oc->proc oc->rands oc->rator run run* prt
    extend-enforce-fns extend-reify-fns enforce-fns reify-fns

    ;; mk
    walk walk* var? lambdag@ mzerog unitg onceo
    conde conda condu ifa ifu project fresh :)
  
  (import
    (rnrs)
    (only (chezscheme) make-parameter)
    (mk))

(define any/var?
  (lambda (p)
    (cond
      ((var? p) #t)
      ((pair? p)
       (or (any/var? (car p)) (any/var? (cdr p))))
      (else #f))))

(define any-relevant/var?
  (lambda (t x*)
    (cond
      ((var? t) (memq t x*))
      ((pair? t)
       (or (any-relevant/var? (car t) x*)
           (any-relevant/var? (cdr t) x*)))
      (else #f))))

(define prefix-s
  (lambda (s s^)
    (cond
      ((null? s) s^)
      (else
        (let loop ((s^ s^))
          (cond
            ((eq? s^ s) '())
            (else (cons (car s^) (loop (cdr s^))))))))))

(define empty-s '())

(define ext-s
  (lambda (x v s)
    (cons `(,x . ,v) s)))

(define size-s
  (lambda (x)
    (length x)))

(define update-s
  (lambda (x v)
    (lambdam@ (a : s c)
      (let ((s^ (ext-s x v s)))
        ((run-constraints (if (var? v) `(,x ,v) `(,x)) c)
         (make-a s^ c))))))

(define empty-c '())

(define ext-c
  (lambda (oc c)
    (cond
     ((any/var? (oc->rands oc))
      (cons oc c))
     (else c))))

(define update-c
  (lambda (oc)
    (lambdam@ (a : s c)
      (make-a s (ext-c oc c)))))

(define empty-a (lambda () (cons empty-s empty-c)))
(define make-a (lambda (s c) (cons s c)))

(define goal-construct
  (lambda (fm)
    (lambdag@ (a)
      (cond
        ((fm a) => unitg)
        (else (mzerog))))))

(define-syntax lambdam@
  (syntax-rules (:)
    ((_ (a) e) (lambda (a) e))
    ((_ (a : s c) e)
     (lambdam@ (a) (let ((s (car a)) (c (cdr a))) e)))))

(define identitym (lambdam@ (a) a))

(define composem
  (lambda (fm f^m)
    (lambdam@ (a)
      (let ((a (fm a)))
        (and a (f^m a))))))

(define-syntax build-oc
  (syntax-rules ()
    ((_ op arg ...)
     (build-oc-aux op (arg ...) () (arg ...)))))

(define-syntax build-oc-aux
  (syntax-rules ()
    ((_ op () (z ...) (arg ...))
     (let ((z arg) ...) `(,(op z ...) . (op ,z ...))))
    ((_ op (arg0 arg ...) (z ...) args)
     (build-oc-aux op (arg ...) (z ... q) args))))

(define oc->proc car)
(define oc->rands cddr)
(define oc->rator cadr)

(define run-constraints
  (lambda (x* c)
    (cond
      ((null? c) identitym)
      ((any-relevant/var? (oc->rands (car c)) x*)
       (composem
         (rem/run (car c))
         (run-constraints x* (cdr c))))
      (else (run-constraints x* (cdr c))))))

(define rem/run
  (lambda (oc)
    (lambdam@ (a : s c)
      (cond
        ((memq oc c)
         (let ((c^ (remq oc c)))
           ((oc->proc oc) (make-a s c^))))
        (else a)))))

(define enforce-fns (make-parameter '()))

(define extend-enforce-fns
  (lambda (fn)
    (enforce-fns (cons fn (enforce-fns)))))

(define enforce-constraints
  (lambda (x)
    (lambdag@ (a : s c)
      ((let loop ((fn* (enforce-fns)))
         (cond
           ((null? fn*) unitg)
           (else
             (fresh ()
               ((car fn*) x)
               (loop (cdr fn*))))))
       a))))

(define reify-fns (make-parameter '()))

(define extend-reify-fns
  (lambda (fn)
    (reify-fns (cons fn (reify-fns)))))

(define reify-s
  (lambda (v s)
    (let ((v (walk v s)))
      (cond
        ((var? v) `((,v . ,(reify-n (size-s s))) . ,s))
        ((pair? v) (reify-s (cdr v) (reify-s (car v) s)))
        (else s)))))

(define reify-n
  (lambda (n)
    (string->symbol
      (string-append "_" "." (number->string n)))))

(define reify
  (lambda (x)
    (lambdag@ (a : s c)
      (let* ((v (walk* x s))
             (r (reify-s v empty-s)))
        (cond
          ((null? r) (choiceg v empty-f))
          (else
            (let ((v (walk* v r)))
              ((reify-constraints v r) a))))))))

(define reify-constraints
  (lambda (v r)
    (lambdag@ (a : s c)
      (let ((c (apply append
                 (map (lambda (fn) ((fn v r) a)) (reify-fns)))))
        (cond
          ((null? c) (choiceg v empty-f))
          (else (choiceg `(,v : . ,c) empty-f)))))))

(define-syntax run
  (syntax-rules ()
    ((_ n (x) g0 g1 ...)
     (take n
       (lambdaf@ ()
         ((fresh (x) g0 g1 ...
            (enforce-constraints x) (reify x))
          (empty-a)))))))

(define-syntax run*
  (syntax-rules ()
    ((_ (x) g ...) (run #f (x) g ...))))

)

(import (ck))
