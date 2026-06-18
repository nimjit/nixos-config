;; ── Theme ────────────────────────────────────────────────────────────────────
(add-to-list 'custom-theme-load-path
             (expand-file-name "themes" user-emacs-directory))
(load-theme 'ukiyo t)

;; ── Evil ─────────────────────────────────────────────────────────────────────
;; These two MUST come before (require 'evil)
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(setq evil-undo-system 'undo-redo)
(setq evil-want-C-u-scroll t)

(require 'evil)
(evil-mode 1)

;; Unbind SPC from evil so general.el can use it as a leader
(define-key evil-motion-state-map (kbd "SPC") nil)
(define-key evil-normal-state-map (kbd "SPC") nil)

(require 'evil-collection)
(evil-collection-init)

;; ── which-key ────────────────────────────────────────────────────────────────
(require 'which-key)
(which-key-mode)
(setq which-key-idle-delay 0.4)

;; ── SPC leader ───────────────────────────────────────────────────────────────
(require 'general)
(general-create-definer spc!
  :keymaps '(normal visual motion)
  :prefix "SPC"
  :global-prefix "C-SPC")

(spc!
  ;; Files
  "f f" '(find-file              :wk "find file")
  "f r" '(recentf-open-files     :wk "recent files")
  "f s" '(save-buffer            :wk "save")

  ;; Buffers
  "b b" '(switch-to-buffer       :wk "switch buffer")
  "b k" '(kill-current-buffer    :wk "kill buffer")
  "b n" '(next-buffer            :wk "next buffer")
  "b p" '(previous-buffer        :wk "prev buffer")

  ;; Windows
  "w v" '(split-window-right     :wk "split right")
  "w s" '(split-window-below     :wk "split below")
  "w d" '(delete-window          :wk "close window")
  "w o" '(delete-other-windows   :wk "only this window")
  "w h" '(windmove-left          :wk "→ left")
  "w j" '(windmove-down          :wk "→ down")
  "w k" '(windmove-up            :wk "→ up")
  "w l" '(windmove-right         :wk "→ right")

  ;; Help
  "h f" '(describe-function      :wk "describe function")
  "h k" '(describe-key           :wk "describe key")
  "h v" '(describe-variable      :wk "describe variable")
  "h m" '(describe-mode          :wk "describe mode")

  ;; Quit
  "q q" '(save-buffers-kill-emacs :wk "quit"))

;; ── Misc ─────────────────────────────────────────────────────────────────────
(recentf-mode 1)
(add-hook 'prog-mode-hook 'display-line-numbers-mode)
