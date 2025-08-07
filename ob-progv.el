;;; ob-progv.el --- Programmatic variables for Org Babel blocks -*- lexical-binding: t -*-

;; Copyright (C) 2025 Vitor Leal

;; Author: Vitor Leal <hello@vitorl.com>
;; URL: https://github.com/nvimtor/ob-progv.el
;; Version: 0.1.0
;; Package-Requires: ((emacs) (org))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides a global minor mode, `ob-progv-mode', which
;; advises `org-babel-execute-src-block'. When enabled, header
;; arguments in Emacs Lisp source blocks (e.g., `:my-var value') will
;; dynamically `let'-bind the corresponding variable `my-var' to
;; `value' during the block's execution. This only affects variables
;; that are already defined (via `defvar`, `defcustom`, etc.).
;;
;; To use, simply enable the global minor mode:
;;
;; (ob-progv-mode 1)
;;
;; You can customize `ob-progv-ignored-vars' to prevent certain
;; variables from being bound.

;;; Code:

(require 'cl-lib)
(require 'org)

(defgroup ob-progv nil
  "Programmatic variables for Org Babel blocks."
  :group 'org)

(defcustom ob-progv-ignored-vars
  '(results
    exports
    session
    var
    tangle
    dir
    cmdline
    cache)
  "A list of symbols that `ob-progv-mode' should not bind from header arguments.
This is useful for preventing conflicts with standard Org Babel
header arguments."
  :type '(repeat symbol)
  :group 'ob-progv)

(defun ob-progv--advice (orig-fn &rest args)
  "Advise `org-babel-execute-src-block' to temporarily set Emacs Lisp
variables from src block headers.

For any header argument like `:my-var value', if a variable named
`my-var' exists, is bound, and is not in `ob-progv-ignored-vars',
it will be let-bound to `value' during the execution of the src block."
  (let* ((info (nth 1 args))
         (header-args (nth 2 info))
         (vars-to-bind '())
         (vals-to-bind '()))
    (dolist (pair header-args)
      (let* ((key-keyword (car pair))
             (value (cdr pair))
             (var-symbol (intern (substring (symbol-name key-keyword) 1))))
        (when (and (boundp var-symbol)
                   (not (memq var-symbol ob-progv-ignored-vars)))
          (push var-symbol vars-to-bind)
          (push value vals-to-bind))))
    (if vars-to-bind
        (cl-progv vars-to-bind vals-to-bind
          (apply orig-fn args))
      (apply orig-fn args))))

(define-minor-mode ob-progv-mode
  "Globally advise `org-babel-execute-src-block' to bind variables from headers."
  :init-value nil
  :lighter " Ob-Progv"
  :global t
  (if ob-progv-mode
      (advice-add 'org-babel-execute-src-block :around #'ob-progv--advice)
    (advice-remove 'org-babel-execute-src-block #'ob-progv--advice)))

(provide 'ob-progv)

;;; ob-progv.el ends here
