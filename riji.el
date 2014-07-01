;;; riji.el --- Riji blog system for Emacs -*- lexical-binding: t; -*-

;; Copyright (C) 2014 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-riji
;; Version: 0.01
;; Package-Requires: ((cl-lib "0.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'cl-lib)

(declare-function helm "helm")
(declare-function helm-candidate-buffer "helm")

(defgroup riji nil
  "riji blog system"
  :group 'blog)

(defcustom riji-default-directory "~/riji/"
  "Default directory of riji"
  :type 'directory
  :group 'riji)

(defcustom riji-directories nil
  "Base directory of riji"
  :type '(repeat directory)
  :group 'riji)

(defsubst riji--construct-entry-name (date index)
  (format "%s-%02d.md" date index))

(defun riji--decide-entry-name (dir)
  (let* ((date (format-time-string "%Y-%m-%d"))
         (index 1)
         (entry (riji--construct-entry-name date index)))
    (let ((default-directory dir))
      (while (file-exists-p entry)
        (cl-incf index)
        (setq entry (riji--construct-entry-name date index))))
    (concat dir entry)))

(defun riji--top-directory ()
  (let ((dir (locate-dominating-file default-directory ".git/")))
    (unless dir
      (error "Here is not git repository."))
    (expand-file-name dir)))

(defvar riji--read-directory-history '())

(defun riji--read-directory ()
  (let* ((prompt (format "Riji Directory[Default %s]: " riji-default-directory))
         (dir (completing-read prompt (cons riji-default-directory riji-directories)
                               nil nil nil
                               'riji--read-directory-history riji-default-directory)))
    (setq dir (file-name-as-directory dir))
    (unless (file-directory-p dir)
      (error "Invalid directory: %s" dir))
    dir))

;;;###autoload
(defun riji-entry ()
  (interactive)
  (let* ((dir (riji--read-directory))
         (entry-dir (concat dir "article/entry/")))
    (unless (file-directory-p entry-dir)
      (error "%s is not setuped. Please exec 'riji setup' in %s" dir dir))
    (let ((entry-file (riji--decide-entry-name entry-dir)))
      (find-file entry-file)
      (insert (concat "tags: blah" "\n" "---" "\n" "# title")))))

;;;###autoload
(defun riji-publish ()
  (interactive)
  (let ((default-directory (riji--top-directory)))
    (with-temp-buffer
      (unless (zerop (call-process "riji" nil t nil "publish"))
        (error "Failed: 'riji publish'"))
      (goto-char (point-min))
      (unless (search-forward "done." nil t)
        (message "fatal error: '%s" cmd)))))

;;
;; helm interface
;;

(defun helm-riji--init ()
  (let* ((riji-dir (riji--read-directory))
         (default-directory riji-dir))
    (let* ((topdir (riji--top-directory))
           (default-directory topdir))
      (with-current-buffer (helm-candidate-buffer 'global)
        (let* ((article-dir (expand-file-name (concat topdir "article")))
               (cmd (format "find %s -type f -name '*.md'|sort" article-dir)))
          (unless (zerop (call-process-shell-command cmd nil t))
            (error "Faild: %s" cmd)))))))

(defvar helm-source-riji
  '((name . "Riji Entries")
    (init . helm-riji--init)
    (candidates-in-buffer)
    (type . file)))

;;;###autoload
(defun helm-riji ()
  (interactive)
  (unless (featurep 'helm)
    (error "helm is not installed or disabled."))
  (let ((buf (get-buffer-create "*helm riji*")))
    (helm :sources helm-source-riji :buffer buf)))

(provide 'riji)

;;; riji.el ends here
