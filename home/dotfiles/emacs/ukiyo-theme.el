;;; ukiyo-theme.el --- Ukiyo dark theme  -*- lexical-binding: t -*-
;; Converted from themes/ukiyo.nix (base16 palette by Thijmen)

(deftheme ukiyo "Ukiyo — warm dark theme based on Japanese woodblock print aesthetics.")

(let ((base00 "#372d29")   ; main background
      (base01 "#413632")   ; lighter background / status bars
      (base02 "#504431")   ; selection background
      (base03 "#868074")   ; comments / inactive
      (base04 "#b2a699")   ; secondary text
      (base05 "#ccc2b7")   ; main text
      (base06 "#ddd5cc")   ; lighter text
      (base07 "#eee8e2")   ; lightest text
      (base08 "#ce631c")   ; warm orange-red — errors, deleted
      (base09 "#e77a59")   ; orange — warnings
      (base0A "#ba945f")   ; yellow/gold — types, highlights
      (base0B "#da7b5f")   ; warm red — strings, success
      (base0C "#da9517")   ; warm gold — builtins, special
      (base0D "#e0ba86")   ; gold accent — keywords, links (blue slot)
      (base0E "#ba945f")   ; warm yellow — regex, special vars (magenta slot)
      (base0F "#645743"))  ; brown — deprecated
  (custom-theme-set-faces
   'ukiyo

   ;; ── Core ─────────────────────────────────────────────────────────────────
   `(default              ((t :foreground ,base05 :background ,base00)))
   `(cursor               ((t :background ,base0D)))
   `(region               ((t :background ,base02)))
   `(fringe               ((t :background ,base01 :foreground ,base03)))
   `(highlight            ((t :background ,base02)))
   `(hl-line              ((t :background ,base01)))
   `(vertical-border      ((t :foreground ,base02)))
   `(window-divider       ((t :foreground ,base02)))
   `(minibuffer-prompt    ((t :foreground ,base0D :weight bold)))
   `(shadow               ((t :foreground ,base03)))
   `(secondary-selection  ((t :background ,base02)))
   `(trailing-whitespace  ((t :background ,base08)))
   `(escape-glyph         ((t :foreground ,base09)))
   `(homoglyph            ((t :foreground ,base09)))
   `(error                ((t :foreground ,base08 :weight bold)))
   `(warning              ((t :foreground ,base09 :weight bold)))
   `(success              ((t :foreground ,base0B :weight bold)))
   `(link                 ((t :foreground ,base0D :underline t)))
   `(link-visited         ((t :foreground ,base0E :underline t)))
   `(button               ((t :foreground ,base0D :underline t)))
   `(header-line          ((t :foreground ,base04 :background ,base01)))
   `(tooltip              ((t :foreground ,base05 :background ,base01)))

   ;; ── Line numbers ─────────────────────────────────────────────────────────
   `(line-number              ((t :foreground ,base03 :background ,base01)))
   `(line-number-current-line ((t :foreground ,base05 :background ,base01 :weight bold)))

   ;; ── Mode line ─────────────────────────────────────────────────────────────
   `(mode-line          ((t :foreground ,base05 :background ,base01
                            :box (:line-width 1 :color ,base02))))
   `(mode-line-inactive ((t :foreground ,base03 :background ,base00
                            :box (:line-width 1 :color ,base02))))
   `(mode-line-buffer-id ((t :foreground ,base0D :weight bold)))
   `(mode-line-emphasis  ((t :foreground ,base05 :weight bold)))

   ;; ── Font lock ─────────────────────────────────────────────────────────────
   `(font-lock-comment-face           ((t :foreground ,base03 :slant italic)))
   `(font-lock-comment-delimiter-face ((t :foreground ,base03 :slant italic)))
   `(font-lock-doc-face               ((t :foreground ,base03 :slant italic)))
   `(font-lock-string-face            ((t :foreground ,base0B)))
   `(font-lock-keyword-face           ((t :foreground ,base0D :weight bold)))
   `(font-lock-builtin-face           ((t :foreground ,base0C)))
   `(font-lock-function-name-face     ((t :foreground ,base0D)))
   `(font-lock-variable-name-face     ((t :foreground ,base05)))
   `(font-lock-type-face              ((t :foreground ,base09)))
   `(font-lock-constant-face          ((t :foreground ,base0A)))
   `(font-lock-warning-face           ((t :foreground ,base09 :weight bold)))
   `(font-lock-preprocessor-face      ((t :foreground ,base09)))
   `(font-lock-negation-char-face     ((t :foreground ,base08)))
   `(font-lock-regexp-grouping-backslash ((t :foreground ,base0A)))
   `(font-lock-regexp-grouping-construct ((t :foreground ,base0D)))

   ;; ── Search ───────────────────────────────────────────────────────────────
   `(isearch      ((t :foreground ,base00 :background ,base0D)))
   `(isearch-fail ((t :foreground ,base00 :background ,base08)))
   `(lazy-highlight ((t :foreground ,base00 :background ,base0A)))
   `(match        ((t :foreground ,base00 :background ,base0B)))

   ;; ── Completions / minibuffer ──────────────────────────────────────────────
   `(completions-common-part      ((t :foreground ,base0D)))
   `(completions-first-difference ((t :foreground ,base09 :weight bold)))

   ;; ── Parens ───────────────────────────────────────────────────────────────
   `(show-paren-match    ((t :background ,base02 :foreground ,base0D :weight bold)))
   `(show-paren-mismatch ((t :background ,base08 :foreground ,base07)))

   ;; ── Org mode ─────────────────────────────────────────────────────────────
   `(org-level-1   ((t :foreground ,base0D :weight bold   :height 1.15)))
   `(org-level-2   ((t :foreground ,base0C :weight bold   :height 1.10)))
   `(org-level-3   ((t :foreground ,base09 :weight bold   :height 1.05)))
   `(org-level-4   ((t :foreground ,base0B :weight normal)))
   `(org-level-5   ((t :foreground ,base0A)))
   `(org-level-6   ((t :foreground ,base0C)))
   `(org-level-7   ((t :foreground ,base04)))
   `(org-level-8   ((t :foreground ,base04)))
   `(org-link      ((t :foreground ,base0D :underline t)))
   `(org-code      ((t :foreground ,base0B :background ,base01)))
   `(org-verbatim  ((t :foreground ,base0C :background ,base01)))
   `(org-block     ((t :background "#2b2320")))
   `(org-block-begin-line ((t :foreground ,base03 :background "#2b2320" :slant italic)))
   `(org-block-end-line   ((t :foreground ,base03 :background "#2b2320" :slant italic)))
   `(org-tag              ((t :foreground ,base03 :weight normal)))
   `(org-todo             ((t :foreground ,base08 :weight bold)))
   `(org-done             ((t :foreground ,base0B :weight normal)))
   `(org-headline-done    ((t :foreground ,base03)))
   `(org-date             ((t :foreground ,base0C :underline t)))
   `(org-document-title   ((t :foreground ,base0D :weight bold :height 1.3)))
   `(org-document-info    ((t :foreground ,base04)))
   `(org-special-keyword  ((t :foreground ,base03)))
   `(org-meta-line        ((t :foreground ,base03 :slant italic)))
   `(org-drawer           ((t :foreground ,base03)))
   `(org-property-value   ((t :foreground ,base04)))
   `(org-table            ((t :foreground ,base04)))
   `(org-formula          ((t :foreground ,base09)))
   `(org-checkbox         ((t :foreground ,base0A :weight bold)))
   `(org-priority         ((t :foreground ,base09)))

   ;; ── Magit / diffs ────────────────────────────────────────────────────────
   `(diff-added          ((t :foreground ,base0B)))
   `(diff-removed        ((t :foreground ,base08)))
   `(diff-changed        ((t :foreground ,base0A)))
   `(diff-header         ((t :foreground ,base0D)))
   `(diff-file-header    ((t :foreground ,base0D :weight bold)))
   `(diff-hl-insert      ((t :background ,base0B :foreground ,base0B)))
   `(diff-hl-delete      ((t :background ,base08 :foreground ,base08)))
   `(diff-hl-change      ((t :background ,base0A :foreground ,base0A)))

   ;; ── Vertico ──────────────────────────────────────────────────────────────
   `(vertico-current  ((t :background ,base02)))

   ;; ── Which-key ────────────────────────────────────────────────────────────
   `(which-key-key-face               ((t :foreground ,base0D :weight bold)))
   `(which-key-separator-face         ((t :foreground ,base03)))
   `(which-key-description-face       ((t :foreground ,base05)))
   `(which-key-group-description-face ((t :foreground ,base0C)))
   `(which-key-command-description-face ((t :foreground ,base04)))

   ;; ── Dired ────────────────────────────────────────────────────────────────
   `(dired-directory ((t :foreground ,base0D :weight bold)))
   `(dired-symlink   ((t :foreground ,base0C)))
   `(dired-marked    ((t :foreground ,base09 :weight bold)))
   `(dired-flagged   ((t :foreground ,base08 :weight bold)))
   `(dired-header    ((t :foreground ,base0A :weight bold)))

   ;; ── Marginalia ───────────────────────────────────────────────────────────
   `(marginalia-documentation ((t :foreground ,base03 :slant italic)))
   `(marginalia-file-priv-dir ((t :foreground ,base0D)))

   ;; ── Elfeed ───────────────────────────────────────────────────────────────
   `(elfeed-search-date-face    ((t :foreground ,base03)))
   `(elfeed-search-title-face   ((t :foreground ,base05)))
   `(elfeed-search-unread-title-face ((t :foreground ,base05 :weight bold)))
   `(elfeed-search-feed-face    ((t :foreground ,base0C)))
   `(elfeed-search-tag-face     ((t :foreground ,base0B)))
   ))

(provide-theme 'ukiyo)
;;; ukiyo-theme.el ends here
