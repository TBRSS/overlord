;;;; overlord.asd
(in-package :asdf)

(assert (uiop:version< "3.1" (asdf:asdf-version)))

(defsystem "overlord"
  :description "Experimental build/module system."
  :author "Paul M. Rodriguez <pmr@ruricolist.com>"
  :license "MIT"
  :version (:read-file-form "version.sexp")
  :class :package-inferred-system
  :depends-on ("overlord/all")
  :in-order-to ((test-op (test-op "overlord/tests")))
  :perform (test-op (o c) (symbol-call :overlord/tests :run-overlord-tests)))
