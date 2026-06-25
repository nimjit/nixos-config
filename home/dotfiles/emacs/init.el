;; Tangle config.org → config.el if newer, then load it.
;; Edit ~/.config/emacs/config.org directly — no Nix rebuild needed.
(org-babel-load-file (expand-file-name "config.org" user-emacs-directory))
