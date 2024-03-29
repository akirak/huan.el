;;; huan.el --- Replace things with predefined alternatives -*- lexical-binding: t -*-

(require 'cl-lib)
(require 'thingatpt)
(require 'subr-x)

(defgroup huan nil
  "Replace symbols with predefined alternatives."
  :group 'editing
  :prefix "huan-")

(defcustom huan-mode-symbols-alist
  '((emacs-lisp-mode
     ("defun" "cl-defun")
     ("defmacro" "cl-defmacro")
     ("cl-defgeneric" "cl-defmethod")
     ("let" "let*")
     ("eq" "eql" "equal")
     ("memq" "memql" "member")
     ("defvar" "defconst" "defcustom")
     ("cl-flet" "cl-flet*" "cl-labels")
     ("thunk-let" "thunk-let*")
     ("eval-after-load" "with-eval-after-load")
     ("add-hook" "remove-hook")
     ("advice-add" "advice-remove")
     ("ad-activate" "ad-deactivate")))
  "FIXME"
  :type '(alist :key-type (symbol :tag "Major mode")
                :value-type (repeat (repeat string))))

;;;###autoload
(defun huan-defun ()
  "Change the type of the defun at point."
  (interactive)
  (save-excursion
    (beginning-of-defun-raw)
    (when (re-search-forward "\\b" nil t)
      (huan-symbol))))

;;;###autoload
(defun huan-symbol ()
  "Change the symbol at point."
  (interactive)
  (when-let* ((mode (apply #'derived-mode-p (mapcar #'car huan-mode-symbols-alist)))
              (entries (cdr (assq mode huan-mode-symbols-alist))))
    (pcase (bounds-of-thing-at-point 'symbol)
      (`(,start . ,end)
       (let ((cur (buffer-substring-no-properties start end)))
         (if-let (entry (cl-find-if (lambda (list) (member cur list))
                                    entries))
             (let ((new (huan--maybe-complete-candidate cur entry)))
               (save-excursion
                 (delete-region start end)
                 (goto-char start)
                 (insert new)))
           (let (message-log-max)
             (message "There is no alternative defined for the symbol"))))))))

(defun huan--maybe-complete-candidate (cur candidates)
  "Pick an alternative to CUR from CANDIDATES."
  (let ((candidates (cl-remove cur candidates :test #'equal)))
    (if (= 1 (length candidates))
        (car candidates)
      (completing-read (format "Replace %s with: " cur)
                       candidates))))

(provide 'huan)
;;; huan.el ends here
