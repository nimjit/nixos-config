;; init.el — tangles config.org → ~/.cache/emacs/config.el, then loads it.
;; Re-tangles automatically whenever config.org is newer (i.e. after each rebuild).
;; To force re-tangle manually: delete ~/.cache/emacs/config.el and restart Emacs.
(let* ((org (expand-file-name "config.org" user-emacs-directory))
       (el  (expand-file-name "config.el"  (expand-file-name "~/.cache/emacs")))
       (elc (concat el "c")))
  (make-directory (file-name-directory el) t)
  (when (or (not (file-exists-p el))
            (file-newer-than-file-p org el))
    (require 'org)
    (require 'ob-tangle)
    (org-babel-tangle-file org el "emacs-lisp")
    ;; Re-compile after retangle
    (when (file-exists-p elc) (delete-file elc))
    (byte-compile-file el))
  ;; Load .elc if fresh, otherwise .el
  (if (and (file-exists-p elc)
           (file-newer-than-file-p elc el))
      (load-file elc)
    (load-file el)))
