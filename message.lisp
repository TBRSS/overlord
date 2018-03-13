(defpackage :overlord/message
  (:use :cl :alexandria :serapeum
    :overlord/global-state)
  (:import-from :overlord/types :overlord-condition)
  (:import-from :overlord/specials :use-threads-p)
  (:export
   :overlord-message
   :message
   :*message-stream*))
(in-package :overlord/message)

(define-global-state *message-stream*
    (make-synonym-stream '*error-output*)
  "The stream printed to by the default message handler.")

(defun message (control &rest args)
  (let* ((stream *message-stream*)
         (control
           (if (stringp control)
               (string-right-trim "." control)
               control)))
    (flet ((message (stream)
             (format stream "~&[Overlord] ~?~%" control args)))
      (if (use-threads-p)
          ;; Write the message en bloc to try to avoid interleaving
          ;; messages.
          (write-string
           (with-output-to-string (stream)
             (message stream))
           stream)
          (message stream)))))

(define-compiler-macro message (&whole call format-control &rest format-arguments)
  (if (not (stringp format-control)) call
      (let ((format-control (string-right-trim "." format-control)))
        `(message (formatter ,format-control) ,@format-arguments))))
