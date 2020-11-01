;;; background-job.el --- Iterate an iterator forward in the background -*- lexical-binding: t -*-

;; Author: Kisaragi Hiu <mail@kisaragi-hiu.com>
;; Version: 1.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: extensions
;; Homepage: https://kisaragi-hiu/projects/background-job.el


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Iterate an iterator forward in the background.
;; Importantly, the “job” pauses when there is user input.

;;; Code:

(require 'generator)

(defconst background-job-idle-time 1
  "Number of seconds of idle time before background jobs start running again.")

(defvar background-job-list nil
  "List of currently active \"background jobs\".

A \"background job\" as defined in this library is actually just
a timer.")

(defun background-job-start (iterator &optional callback)
  "Create a timer to call ITERATOR after some idle time.

Iterate ITERATOR until there is user input; resume after some
idle time.

CALLBACK is called when `iter-end-of-sequence' is raised."
  (let ((timer
         (run-with-idle-timer
          background-job-idle-time :repeat
          (lambda ()
            (condition-case nil
                (while (not (input-pending-p))
                  (iter-next iterator))
              (iter-end-of-sequence
               ;; effectively the callback
               (cancel-timer timer)
               (setq background-job-list (remove timer background-job-list))
               (when callback
                 (funcall callback))))))))
    (push timer background-job-list)
    timer))

(defun background-job-stop (timer)
  "Stop TIMER and remove it from `background-job-list'."
  (cancel-timer timer)
  (setq background-job-list (remove timer background-job-list))
  nil)

(defun background-job-stop-all ()
  "Stop all timers in `background-job-list'."
  (dolist (job background-job-list)
    (background-job-stop job)))

(provide 'background-job)

;;; background-job.el ends here
