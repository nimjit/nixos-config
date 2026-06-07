;; early-init.el — fires before packages and the frame are set up
(setq inhibit-startup-screen t)
(push '(menu-bar-lines  . 0) default-frame-alist)
(push '(tool-bar-lines  . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)
;; Defer GC during startup (speeds up load); restore to 16 MB after
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
  (lambda () (setq gc-cons-threshold (* 16 1024 1024))))
