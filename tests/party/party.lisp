#lang overlord/simple-module

(:export (#'balloon/make make)
         (#'balloon/push push*)
         #'push!
         #'make-party
         (#'party-pop! pop!))

(:import stack
  :from "stack.lisp"
  :binding (#'make #'push! #'pop!)      ;not empty!
  )

(:import balloon
  :from "balloons.lisp"
  :binding :all-as-functions
  :prefix balloon/)

(defun make-party ()
  (let ((s (make)))                     ;from stack
    (push! s (balloon/make 10 10))
    (push! s (balloon/make 12 9))
    s))

(defun party-pop! (p)
  (balloon/pop (pop! p)))
