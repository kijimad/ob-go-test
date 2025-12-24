;;; ob-go-test.el --- Execute Go tests in org-babel -*- lexical-binding: t -*-

;; Copyright (C) 2025 Kijima Daigo
;; Created date 2025-12-24 18:53 +0900

;; Author: Kijima Daigo <norimaking777@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: org-babel
;; URL: https://github.com/kijimaD/ob-go-test

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Execute Go tests in org-babel.

;;; Code:
(require 'ob)

(add-to-list 'org-babel-tangle-lang-exts '("go-test" . "go"))

;;;###autoload
(defun org-babel-execute:go-test (body params)
  "Execute BODY as Go test code and return results.
Optional PARAMS can include:
  :package - package name (default: main)
  :verbose - show verbose output"
  (let* ((tmp-dir (make-temp-file "go-test-" t))
         (test-file (expand-file-name "test_test.go" tmp-dir))
         (full-code (ob-go-test-build-code body params)))
    (with-temp-file test-file
      (insert full-code))
    (unwind-protect
        (ob-go-test-run tmp-dir params)
      (delete-directory tmp-dir t))))

(defun ob-go-test-build-code (body params)
  "Build complete Go test file from BODY.
PARAMS can specify :package for package name."
  (let ((package-name (or (cdr (assq :package params)) "main"))
        (imports (ob-go-test-extract-imports body)))
    (concat
     (format "package %s\n\n" package-name)
     "import (\n"
     "\t\"testing\"\n"
     (mapconcat (lambda (imp) (format "\t%s\n" imp)) imports "")
     ")\n\n"
     (ob-go-test-remove-imports body))))

(defun ob-go-test-extract-imports (body)
  "Extract import statements from BODY."
  (let ((imports '()))
    (with-temp-buffer
      (insert body)
      (goto-char (point-min))
      (while (re-search-forward "^\\s-*import\\s-+\"\\([^\"]+\\)\"" nil t)
        (push (format "\"%s\"" (match-string 1)) imports)))
    (reverse imports)))

(defun ob-go-test-remove-imports (body)
  "Remove import statements from BODY."
  (with-temp-buffer
    (insert body)
    (goto-char (point-min))
    (while (re-search-forward "^\\s-*import\\s-+\"[^\"]+\"\n?" nil t)
      (replace-match ""))
    (buffer-string)))

(defun ob-go-test-run (dir params)
  "Run go test in DIR and return results.
PARAMS can specify :verbose for verbose output."
  (let* ((verbose (cdr (assq :verbose params)))
         (args (if verbose "-v" ""))
         (default-directory dir))
    (with-temp-buffer
      ;; Initialize go module
      (call-process "go" nil t nil "mod" "init" "test")

      ;; Download dependencies
      (call-process "go" nil t nil "mod" "tidy")

      ;; Run tests
      (erase-buffer)
      (call-process "go" nil t nil "test" args)
      (buffer-string))))

(provide 'ob-go-test)
;;; ob-go-test.el ends here
