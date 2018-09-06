(defpackage :overlord/target-protocol
  (:use :cl :alexandria :serapeum)
  (:import-from :overlord/stamp :target-timestamp :never)
  (:import-from :overlord/types :hash-code :error*)
  (:import-from :fset :compare :define-cross-type-compare-methods)
  (:export
   ;; Unit types.
   #:root-target
   #:impossible-prereq
   #:trivial-prereq
   ;; Methods that targets should implement.
   #:target-stamp
   #:target-timestamp
   #:target-exists?
   #:target=
   #:hash-target
   #:resolve-target
   #:target-build-script
   #:target-node-label
   #:delay-target
   #:force-target
   #:handle-tag-data
   ;; Other methods.
   #:build-script-target
   #:run-script
   #:record-prereq
   #:record-prereqne
   #:target-in-db?
   #:target-saved-prereqs
   #:target-saved-prereqsne
   #:saved-prereq-target
   #:saved-prereq-stamp
   #:target-up-to-date?
   #:save-temp-prereqs
   #:clear-temp-prereqs
   #:save-temp-prereqsne
   #:clear-temp-prereqsne))
(in-package :overlord/target-protocol)

;;; TODO Add touch-target once you have a good implementation for
;;; Windows.

(defunit root-target
  "The root target.
Building this builds all targets defined in this session \(not all targets in the database).")

(defunit impossible-prereq
  "The target that is always out of date.")

(defunit trivial-prereq
  "The target that is never out of date.")

(defmethod compare ((x root-target) (y root-target)) :equal)
(defmethod compare ((x trivial-prereq) (y trivial-prereq)) :equal)
(defmethod compare ((x impossible-prereq) (y impossible-prereq)) :equal)
(define-cross-type-compare-methods root-target)
(define-cross-type-compare-methods impossible-prereq)
(define-cross-type-compare-methods trivial-prereq)

(defgeneric target-stamp (target)
  (:documentation "Return the stamp of TARGET.")
  (:method (target)
    (target-timestamp target)))

(defgeneric target-timestamp (target)
  (:documentation "Return the timestamp of TARGET.")
  (:method :around (target)
    (let ((f (force-target target)))
      (if (eq f target)
          (call-next-method)
          (target-timestamp f))))
  (:method (target)
    (error* "No timestamp method for target ~a.

Need to specialize one of ~s or ~s for class ~s."
            'target-timestamp
            'target-stamp
            (class-name-of target))))

(defgeneric (setf target-timestamp) (timestamp target)
  (:documentation "Set the timestamp of TARGET.
Not every target type supports this.")
  (:method :around (value target)
    (let ((f (force-target target)))
      (if (eq f target)
          (call-next-method)
          (setf (target-timestamp f) value)))))

(-> target-exists? (t) boolean)
(defgeneric target-exists? (target)
  (:documentation "Does TARGET exists?")
  (:method :around (target)
    (let ((f (force-target target)))
      (if (eq f target)
          (true (call-next-method))
          (target-exists? f))))
  (:method (target)
    (not (eql never (target-timestamp target)))))

(-> target= (t t) boolean)
(defgeneric target= (target1 target2)
  (:documentation "Are TARGET1 and TARGET2 the same?")
  ;; This is OK because we expect objects representing targets to be
  ;; immutable.
  (:method (t1 t2)
    (eql t1 t2))
  (:method :around (t1 t2)
    (or (eql t1 t2)
        (let ((f1 (force-target t1))
              (f2 (force-target t2)))
          (or (eql f1 f2)
              (if (and (eq f1 t1)
                       (eq f2 t2))
                  (call-next-method)
                  (target= f1 f2)))))))

(-> hash-target (t) hash-code)
(defgeneric hash-target (target)
  (:documentation "Hash TARGET.

Two targets that are equal under `target=' should always have the same
hash \(though the reverse is not necessarily true).")
  (:method :around (target)
    (declare (ignore target))
    (assure hash-code
      (call-next-method)))
  (:method (target)
    (sxhash target)))

(defgeneric resolve-target (target &optional base)
  (:documentation "Resolve any relative pathnames in TARGET.

TARGET may be returned unchanged if there are no pathnames to resolve,
but it must not be mutated. If there are pathnames to resolve, TARGET
should be copied.")
  (:method (target &optional base)
    (declare (ignore base))
    target))

(defgeneric target-build-script (target))

(defgeneric target-node-label (target)
  (:documentation "Return a string suitable for logging \(for humans) what target is being built.")
  (:method :around (target)
    (assure string
      (let ((f (force-target target)))
        (if (eq f target)
            (call-next-method)
            (target-node-label f)))))
  (:method (target)
    (princ-to-string target)))

(defgeneric delay-target (target)
  (:method (target)
    target))

(defgeneric force-target (target)
  (:method (target)
    target))

(defgeneric handle-tag-data (tag data))



;;; For internal use.

(defgeneric build-script-target (script))

(defgeneric run-script (task))

(defgeneric record-prereq (target))

(defgeneric save-temp-prereqs (target))

(defgeneric record-prereqne (target))

(defgeneric save-temp-prereqsne (target))

(defgeneric target-in-db? (target))

(defgeneric target-saved-prereqs (target))

(defgeneric target-saved-prereqsne (target))

(defgeneric saved-prereq-target (prereq))

(defgeneric saved-prereq-stamp (prereq))

(defgeneric target-up-to-date? (target))

(defgeneric (setf target-up-to-date?) (value target))

(defgeneric clear-temp-prereqs (target))

(defgeneric clear-temp-prereqsne (target))
