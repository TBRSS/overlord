(defpackage :overlord/import-set
  (:use :cl :alexandria :serapeum :trivia
    :overlord/types)
  (:shadowing-import-from :trivia :@ :plist)
  (:export :expand-import-set
   :import-set=))
(in-package :overlord/import-set)

(deftype public-name ()
  '(or var-alias function-alias macro-alias))

(deftype private-name ()
  'keyword)

(defun public-name+private-name (import)
  (receive (public private)
      (etypecase-of binding-designator import
        (atom (values import import))
        (function-alias (values import (second import)))
        (macro-alias (values import (second import)))
        ((tuple symbol :as import-alias)
         (destructuring-bind (private &key ((:as public))) import
           (values public private))))
    (values (assure public-name public)
            (make-keyword private))))

(defun public-name (import)
  (nth-value 0 (public-name+private-name import)))

(defun private-name (import)
  (nth-value 1 (public-name+private-name import)))

(defun public-name= (x y)
  (equal x y))

(defun rename-import (import new-name)
  (assure binding-designator
    (list (private-name import) :as new-name)))

(defun expand-import-set (import-set get-exports
                          &optional (package *package*))
  (fbind (get-exports)
    (labels ((rec (import-set)
               (ematch import-set
                 (:all
                  (loop for export in (get-exports)
                        for sym = (intern (string export) package)
                        collect `(,export :as ,sym)))
                 (:all-as-functions
                  (loop for export in (get-exports)
                        for sym = (intern (string export) package)
                        collect `(,export :as #',sym)))
                 ((list* :only import-set ids)
                  (only (rec import-set) ids))
                 ((list* :except import-set ids)
                  (except (rec import-set) ids))
                 ((list* :rename import-set renames)
                  (rename (rec import-set) renames))
                 ((list :prefix import-set prefix)
                  (prefix (rec import-set) prefix))
                 ((list :drop-prefix import-set prefix)
                  (drop-prefix (rec import-set) prefix))
                 ((list* :alias import-set renames)
                  (alias (rec import-set) renames)))))
      (rec import-set))))

(defun only (import-set ids)
  (reduce (lambda (out id)
            (if-let (import (find id import-set :test #'named?))
              (cons import out)
              (missing-id id import-set)))
          ids
          :initial-value nil))

(defun except (import-set ids)
  (reduce (lambda (import-set id)
            (if-let (import (find id import-set :test #'named?))
              (remove import import-set)
              (missing-id id import-set))
            (remove-if (op (named? id _))
                       import-set))
          ids
          :initial-value import-set))

(defun rename (import-set renames)
  (reduce (lambda (import-set renaming)
            (receive (old-name new-name) (old-name+new-name renaming)
              (if-let (import (find old-name import-set :test #'named?))
                (cons (rename-import import new-name)
                      (remove import import-set))
                (missing-id old-name import-set))))
          renames
          :initial-value import-set))

(defun alias (import-set renames)
  (reduce (lambda (import-set renaming)
            (receive (old-name new-name) (old-name+new-name renaming)
              (if-let (import (find old-name import-set :test #'named?))
                (cons (rename-import import new-name)
                      import-set)
                (missing-id old-name import-set))))
          renames
          :initial-value import-set))

(defun old-name+new-name (renaming)
  (destructuring-bind (old-name new-name) renaming
    (values old-name new-name)))

(defun prefix (import-set prefix)
  (mass-rename import-set (op (symbolicate prefix _))))

(defun drop-prefix (import-set prefix)
  (flet ((drop-prefix (symbol)
           (eif (string^= prefix symbol)
                (intern (drop (length (string prefix))
                              (symbol-name symbol))
                        (symbol-package symbol))
                symbol)))
    (mass-rename import-set #'drop-prefix)))

(defun mass-rename (import-set rename-fn)
  (loop for import in import-set
        for public-name = (public-name import)
        for new-name = (frob-name public-name rename-fn)
        collect (rename-import import new-name)))

(defun frob-name (name fn)
  (fbind (fn)
    (etypecase-of public-name name
      (var-alias (assure var-alias (fn name)))
      (function-alias (assure function-alias `(function ,(fn (second name)))))
      (macro-alias (assure macro-alias `(macro-function ,(fn (second name))))))))

(defcondition import-set-condition ()
  ())

(defcondition import-set-error (import-set-condition simple-error)
  ())

(defun missing-id (id import-set)
  (error 'import-set-error
         :format-control "Missing id ~a in import set ~s"
         :format-arguments (list id import-set)))

(defun named? (name import)
  (public-name= name (public-name import)))

(defun import-set= (set1 set2)
  (set-equal set1 set2
             :test (lambda (x y)
                     (public-name= (public-name x)
                                   (public-name y)))))