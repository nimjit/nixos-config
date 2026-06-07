# Emacs Setup Plan

## What I found in your vaults

### Personal vault structure
```
Renaissance_Vault_Structure/
  Concepts/      physics (Landau-level notes), philosophy, humanities (~150 files)
  Knowledge/     subdirs: Physics, Philosophy, Mathematics, Languages, etc.
  Essays/        written essays (Capitalism, Art, etc.)
  Sources/       Books/, Papers/, Youtube/
  People/        person notes with template
  Dailies/       YYYY-MM-DD.md format
  Templates/     Books (book template), People.md
  Misc/          scratch
```

### Uni vault structure
```
Uni/
  Classes/       one file per class, contains dataview tables of lectures + assignments
  Lecture/       one file per lecture (frontmatter: class, date, lecture_number)
  Assignments/   one file per assignment (frontmatter: class, grade, deadline)
  Summary/       final summary per class
  Lecture MOC/   map of content per class
  Thesis/
  Uni MOC.md     master overview: all classes, upcoming deadlines
  2026-XX-XX.md  loose session notes at root (no dailies folder)
```

### Plugin → Emacs package mapping

| Obsidian plugin        | Emacs equivalent              | Notes                                          |
|------------------------|-------------------------------|------------------------------------------------|
| dataview               | org-ql                        | query language for org files                   |
| templater-obsidian     | org-capture + org-roam captu  | `<% tp.file.title %>` → `${title}`             |
| typst-mate             | custom org-typst-preview-mode | cursor-away → SVG render; cursor-in → source   |
| rss-dashboard          | elfeed + elfeed-tube          | YouTube via RSS; `mpv` on play                 |
| obsidian-day-planner   | org-agenda time-grid          | built-in; visual scheduling                    |
| obsidian-git           | magit                         | much better                                    |
| calendar               | org-gcal + org-agenda         | two-way Google Calendar sync                   |
| zoottelkeeper          | not needed                    | org-roam handles backlinks automatically       |
| folder-note-plugin     | dired + org-roam              | folder browsing via dired sidebar              |
| waypoint               | org-roam MOC pattern          | manual but cleaner                             |
| inline-math            | org-typst-preview-mode        | same as typst-mate — see Phase 3b              |
| markdown-table-editor  | org-table                     | built-in, excellent                            |
| vim-yank-highlight     | evil-goggles                  | highlights evil operations                     |
| cycle-through-panes    | evil window + perspective     | `SPC w hjkl` + perspective workspaces         |
| quickadd               | org-capture                   | same concept                                   |
| extended-graph         | org-roam-ui                   | browser-based graph view                       |
| obsidian-charts        | org-plot                      | gnuplot backend                                |
| obsidian-regex-replace | query-replace-regexp          | built-in: `M-%`                                |
| settings-search        | which-key + `M-x`             | `M-x` is already a fuzzy command search        |
| chronos                | custom D3.js timeline script  | Python script → HTML timeline; much better     |
| music-player (Misc)    | EMMS + mpv                    | sidebar browser, FLAC/MP3, SPC m m to toggle   |

---

## Design decisions (from answers)

- **Typst math inline rendered**: `org-typst-preview-mode` renders `$...$` fragments
  as inline SVG by calling `typst compile --format svg` — same feel as typst-mate.
  Cursor leaves fragment → renders. Cursor enters → shows source. Toggle with `SPC t p`.
  No LaTeX anywhere: the Typst CLI (already installed) does all rendering.
- **Music player in Emacs**: `emms` backed by mpv browses the local FLAC library at
  `/home/thijmen/Documents/BACKUP/Music Library/`. Sidebar toggles with `SPC t s` or
  `SPC m m`.
- **Separate contexts via perspectives**: you open two Obsidian vaults (personal + uni).
  In Emacs: `perspective.el` creates named workspaces with separate buffer lists.
  Each perspective opens to its own dashboard org file.
- **Navigate by folders**: you browse folder structure, not search/graph. Emacs
  provides `dired` (built-in file browser with evil bindings) and `dired-sidebar`
  (persistent sidebar). This replaces the Obsidian file tree.
- **Backlinks are low priority**: you almost never use the backlinks panel — don't
  clutter the UI with it. Include `SPC n b` to toggle it, but keep it hidden by default.
- **Single-pane focus**: olivetti + no sidebar by default. Split only when needed
  (lecture on left, summary on right for the transclusion workflow).
- **Unified org-roam database**: one database spanning `~/org/`. Perspectives handle
  the separation, not separate databases.
- **PDF viewing in Emacs**: `pdf-tools` for viewing lecture slides + papers. No
  annotation-to-notes linking needed — just viewing.
- **Google Calendar sync**: `org-gcal` replaces calcurse. Two-way sync.
- **Spell check**: English + Dutch. `jinx` with both dictionaries.
- **Keybindings match Neovim**: SPC ff, SPC gg, SPC bb etc. should be identical
  to neovim where they overlap. Check `home/dotfiles/neovim/init.lua` when writing
  the final config.
- **Complete beginner**: config should work out of the box. Keep `use-package` blocks
  well-commented so they can be understood when the user explores later.
- **Migration first, then switch**: run pandoc conversion on both vaults, verify
  org-roam DB, then switch — keep Obsidian running until satisfied.

---

## Directory structure

```
~/org/
  personal/
    concepts/       atomic concept notes (replaces Concepts/)
    knowledge/
      physics/      larger reference docs (replaces Knowledge/Physics/)
      philosophy/   (replaces Knowledge/Philosophy/)
      mathematics/  (etc.)
      languages/
      meta/
    essays/         replaces Essays/
    sources/
      books/        replaces Sources/Books/  (library.bib covers metadata)
      papers/       replaces Sources/Papers/
      youtube/      replaces Sources/Youtube/
    people/         replaces People/
    misc/
  uni/
    classes/        one .org file per class (replaces Classes/)
    lectures/       one .org file per lecture (replaces Lecture/)
    assignments/    one .org file per assignment OR single assignments.org
    summary/        replaces Summary/
    thesis/
  daily/            org-roam-dailies (shared across contexts)
  library.bib       single BibTeX file for all books + papers (Syncthing-synced)
  inbox.org         quick capture — process regularly
  agenda.org        scheduled items and global TODOs
```

---

## Phase 1 — Nix setup

### `home/emacs.nix` — new file
```nix
{ pkgs, ... }: {
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-pgtk;  # Wayland-native: important for sway later
    extraPackages = epkgs: with epkgs; [
      # ── Evil ─────────────────────────────────────────────────────────────
      evil
      evil-collection    # evil in every buffer (magit, dired, org, etc.)
      evil-surround      # cs, ds, ys surround motions
      evil-commentary    # gc to comment
      evil-goggles       # flash highlighting on yank/delete/paste
      general            # SPC-leader keybinding framework

      # ── UI ───────────────────────────────────────────────────────────────
      which-key
      vertico            # vertical minibuffer completion
      marginalia         # annotations in completion (file size, doc strings)
      consult            # enhanced commands: consult-line, consult-grep, etc.
      orderless          # fuzzy/space-separated matching
      embark             # action menu on any completion candidate
      embark-consult

      # ── Navigation ───────────────────────────────────────────────────────
      avy                # jump to char/word/line (like easy-motion)
      projectile         # project-aware commands

      # ── Git ──────────────────────────────────────────────────────────────
      magit
      diff-hl            # gutter diff indicators

      # ── Org ──────────────────────────────────────────────────────────────
      org-roam           # zettelkasten, backlinks, graph
      org-roam-ui        # browser graph view (localhost)
      org-ql             # query language (replaces dataview)
      org-superstar      # prettier headings
      org-modern         # cleaner org rendering (tables, tags, todo)
      org-transclusion   # embed sections from other org files (lecture → summary)

      # ── Citations / library ──────────────────────────────────────────────
      citar              # citation management (books + papers, .bib backend)
      citar-org          # org-cite integration for citar
      org-roam-bibtex    # link bibtex entries to org-roam notes

      # ── Planning ─────────────────────────────────────────────────────────
      # org-timeblock    # visual time blocking — check if in nixpkgs 26.05

      # ── Reading / RSS ────────────────────────────────────────────────────
      elfeed
      elfeed-org         # manage feed list in an org file
      elfeed-tube        # YouTube in elfeed (plays via mpv)

      # ── Typst ────────────────────────────────────────────────────────────
      typst-ts-mode      # tree-sitter major mode for .typ files
      # ox-typst         # org→Typst exporter — check if in nixpkgs 26.05; may need overlay

      # ── Context workspaces ───────────────────────────────────────────────
      perspective        # named workspaces (personal / uni), separate buffer lists

      # ── File browsing ────────────────────────────────────────────────────
      dired-sidebar      # persistent file tree sidebar (replaces Obsidian file tree)

      # ── PDF viewing ──────────────────────────────────────────────────────
      pdf-tools          # view PDFs inside Emacs (lecture slides, papers)

      # ── Calendar ─────────────────────────────────────────────────────────
      org-gcal           # two-way Google Calendar sync

      # ── Writing / appearance ─────────────────────────────────────────────
      mixed-pitch        # variable font for org prose, mono for code
      olivetti           # centered writing mode
      jinx               # fast spell checking (English + Dutch)

      # ── Code / LSP ───────────────────────────────────────────────────────
      # eglot is built-in (Emacs 29+)
      treesit-auto       # auto tree-sitter grammars

      # ── Misc ─────────────────────────────────────────────────────────────
      markdown-mode
      vterm              # fast terminal (for quick commands without leaving Emacs)
    ];
  };

  xdg.configFile."emacs/init.el".source       = ./dotfiles/emacs/init.el;
  xdg.configFile."emacs/early-init.el".source = ./dotfiles/emacs/early-init.el;
  xdg.configFile."emacs/elfeed.org".source    = ./dotfiles/emacs/elfeed.org;
}
```

### Add to `modules/common.nix` packages:
```nix
tinymist   # Typst LSP (used by typst-ts-mode via eglot)
```

### Add to `home/default.nix` imports:
```nix
./emacs.nix
```

---

## Phase 2 — `early-init.el`

### `home/dotfiles/emacs/early-init.el`
```elisp
(setq inhibit-startup-screen t)
(push '(menu-bar-lines  . 0) default-frame-alist)
(push '(tool-bar-lines  . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(internal-border-width . 0) default-frame-alist)
(push '(undecorated . t) default-frame-alist)  ; no title bar decorations
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'emacs-startup-hook
  (lambda () (setq gc-cons-threshold (* 16 1024 1024))))
```

---

## Phase 3 — `init.el` — core config

### 3a: Evil mode
```elisp
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)   ; required before evil-collection
  (setq evil-undo-system 'undo-redo)
  (setq evil-want-C-u-scroll t)     ; C-u scrolls (like vim)
  (setq evil-search-module 'evil-search)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config (evil-collection-init))

(use-package evil-goggles
  :after evil
  :config
  (evil-goggles-mode)
  (evil-goggles-use-diff-faces))
```

### 3b: SPC leader (general.el)
```elisp
(use-package general
  :config
  (general-create-definer spc!
    :keymaps '(normal visual emacs)
    :prefix "SPC")

  (spc!
    ;; Files
    "f"  '(:ignore t :wk "file")
    "ff" 'find-file
    "fr" 'consult-recent-file
    "fs" 'save-buffer
    "fS" 'save-some-buffers

    ;; Buffers
    "b"  '(:ignore t :wk "buffer")
    "bb" 'consult-buffer
    "bd" 'kill-buffer
    "bR" 'revert-buffer

    ;; Search
    "s"  '(:ignore t :wk "search")
    "ss" 'consult-line
    "sg" 'consult-grep
    "sp" 'consult-ripgrep   ; ripgrep across project

    ;; Git
    "g"  '(:ignore t :wk "git")
    "gg" 'magit-status
    "gb" 'magit-blame

    ;; Notes (org-roam)
    "n"  '(:ignore t :wk "notes")
    "nf" 'org-roam-node-find
    "ni" 'org-roam-node-insert
    "nb" 'org-roam-buffer-toggle  ; backlinks panel
    "ng" 'org-roam-ui-open        ; graph in browser
    "nc" 'org-capture
    "nd" 'org-roam-dailies-goto-today

    ;; Agenda
    "a"  'org-agenda

    ;; RSS
    "r"  'elfeed

    ;; Open
    "o"  '(:ignore t :wk "open")
    "ot" 'vterm
    "op" 'projectile-find-file
    "ov" 'open-personal-snowflake   ; personal vault snowflake
    "ou" 'open-uni-snowflake        ; uni vault snowflake
    "on" 'open-nixos-snowflake      ; nixos snowflake
    "oV" 'regenerate-snowflakes     ; regenerate all three

    ;; Window (mirrors your hjkl system)
    "w"  '(:ignore t :wk "window")
    "wh" 'evil-window-left
    "wj" 'evil-window-down
    "wk" 'evil-window-up
    "wl" 'evil-window-right
    "ws" 'evil-window-split
    "wv" 'evil-window-vsplit
    "wd" 'evil-window-delete

    ;; Quit
    "q"  '(:ignore t :wk "quit")
    "qq" 'save-buffers-kill-emacs))
```

### 3c: Completion
```elisp
(use-package vertico  :init (vertico-mode))
(use-package marginalia :init (marginalia-mode))
(use-package orderless
  :custom (completion-styles '(orderless basic)))
(use-package consult
  :bind ([remap switch-to-buffer] . consult-buffer))
(use-package embark
  :bind ("C-." . embark-act))
(use-package embark-consult :after (embark consult))
(use-package which-key
  :init (which-key-mode)
  :custom (which-key-idle-delay 0.4))
```

### 3d: Appearance
```elisp
;; Stylix auto-generates ~/.config/emacs/stylix-theme.el — load it:
(load-theme 'modus-operandi-tinted t)  ; fallback if stylix hasn't generated yet
;; (The stylix theme load is injected by home-manager automatically when
;;  stylix.targets.emacs.enable = true, which it is by default)

;; Line numbers in code modes, not in org/prose
(add-hook 'prog-mode-hook 'display-line-numbers-mode)

;; Variable pitch in org, mono in code blocks
(use-package mixed-pitch :hook (org-mode . mixed-pitch-mode))

;; Centered writing
(use-package olivetti
  :custom (olivetti-body-width 88)
  :hook (org-mode . olivetti-mode))

;; Typewriter scroll (you used cm-typewriter-scroll in Obsidian)
(setq scroll-margin 8)

;; Prettier org
(use-package org-superstar :hook (org-mode . org-superstar-mode))
(use-package org-modern
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda)))
```

---

## Phase 3b — Typst math in org-mode

Math in org notes stays as plain Typst syntax — no rendering, no LaTeX, no engine.
You write exactly what you already write in typst-mate:

```org
The Schrödinger equation: $i hbar diff/(diff t) Psi = hat(H) Psi$

For display math, just use a typst code block in the export:
$integral_0^1 f(x) d x = F(1) - F(0)$

Cases: $cases(a "if" x > 0, b "otherwise")$
Dirac notation: $braket(psi, phi)$
```

This is **readable plain text** in org-mode. No rendering in the editor — you
already know the Typst syntax well enough to read it. When you want pretty output,
export to Typst via ox-typst.

### ox-typst export

`ox-typst` is an org-mode exporter backend that outputs `.typ` files. It handles
the Typst math syntax you're already writing:

```elisp
;; org → Typst export
;; ox-typst adds C-c C-e t t (export to .typ file) and C-c C-e t p (compile to PDF)
(with-eval-after-load 'ox
  (require 'ox-typst))
```

**Check availability in nixpkgs 26.05**: `ox-typst` may not be packaged yet.
To check: `nix search nixpkgs ox-typst`. If not found, install via `straight.el`
or add an overlay fetching from GitHub (`emacsmirror/ox-typst` or similar).
Fallback: `nix shell nixpkgs#emacs-packages.ox-typst` to test before committing.

### Typst-ts-mode for standalone .typ files

Dedicated `.typ` files (summaries exported to PDF, thesis chapters) get full
tree-sitter highlighting, tinymist LSP, and compile-on-save:

```elisp
(use-package typst-ts-mode
  :mode "\\.typ\\'"
  :custom
  (typst-ts-mode-watch-options "--open")  ; open PDF on first compile
  :config
  ;; Compile current .typ file: SPC m c
  (general-def :states '(normal) :keymaps 'typst-ts-mode-map
    "SPC m c" 'typst-ts-compile
    "SPC m w" 'typst-ts-mode-watch-toggle))
```

The LSP (tinymist) is already in `modules/common.nix` from Phase 1. Eglot picks it
up automatically when you open a `.typ` file.

---

## Phase 3b-2 — Snowflake visualizations

You have three snowflake HTML visualizations of your config/vault structures.
Emacs provides keybindings to open them in a browser and to regenerate them.

```elisp
(defun open-personal-snowflake ()
  (interactive)
  (browse-url "file:///home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.html"))

(defun open-uni-snowflake ()
  (interactive)
  (browse-url "file:///home/thijmen/Documents/BACKUP/Uni/Obsidian/Uni/uni_snowflake.html"))

(defun open-nixos-snowflake ()
  (interactive)
  (browse-url "file:///etc/nixos/nixos_snowflake.html"))

(defun regenerate-snowflakes ()
  (interactive)
  (async-shell-command
    (concat "python3 /home/thijmen/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/vault_snowflake.py && "
            "python3 /home/thijmen/Documents/BACKUP/Uni/Obsidian/uni_snowflake.py && "
            "python3 /etc/nixos/nixos_snowflake.py")
    "*snowflake-regen*"))

(spc!
  "o v" 'open-personal-snowflake   ; SPC o v → personal vault snowflake
  "o u" 'open-uni-snowflake        ; SPC o u → uni vault snowflake
  "o n" 'open-nixos-snowflake      ; SPC o n → nixos config snowflake
  "o V" 'regenerate-snowflakes)    ; SPC o V → regenerate all three
```

---

## Phase 3c — Context workspaces (replaces separate Obsidian vaults)

You work in two separate Obsidian vaults. In Emacs, `perspective.el` creates named
workspaces (perspectives) with completely separate buffer lists. Switching perspective
feels like switching to a different app context — same Emacs instance, different "space".

```elisp
(use-package perspective
  :custom
  (persp-mode-prefix-key (kbd "C-c C-p"))
  (persp-initial-frame-name "personal")
  :init (persp-mode))
```

### Two perspectives: personal and uni

```elisp
;; Open personal dashboard when switching to "personal" perspective
;; Open uni dashboard when switching to "uni" perspective

(defun perspective-personal ()
  "Switch to personal perspective and open dashboard."
  (interactive)
  (persp-switch "personal")
  (find-file "~/org/personal/dashboard.org"))

(defun perspective-uni ()
  "Switch to uni perspective and open dashboard."
  (interactive)
  (persp-switch "uni")
  (find-file "~/org/uni/dashboard.org"))
```

### SPC keybindings for perspectives:
```elisp
(spc!
  "TAB"   '(:ignore t :wk "workspace")
  "TAB p" 'perspective-personal     ; SPC TAB p → personal
  "TAB u" 'perspective-uni          ; SPC TAB u → uni
  "TAB TAB" 'persp-switch           ; SPC TAB TAB → pick any perspective
  "TAB d" 'persp-kill               ; SPC TAB d → close perspective
  "TAB r" 'persp-rename)            ; SPC TAB r → rename
```

### Dashboard files

`~/org/personal/dashboard.org`:
```org
#+title: Personal
#+STARTUP: content

* Recent
# org-ql block showing recent personal notes
#+BEGIN: org-ql-table :query (ts :from -7) :columns (file ts) :from "~/org/personal/"
#+END:

* Inbox
#+BEGIN: org-ql-table :query (todo "TODO") :from "~/org/inbox.org"
#+END:
```

`~/org/uni/dashboard.org` (replaces Uni MOC.md):
```org
#+title: Uni
#+STARTUP: content

* Classes
#+BEGIN: org-ql-table :query (tags "class") :columns (file (property "year") (property "Q")) :sort '(property "year") :from "~/org/uni/classes/"
#+END:

* Upcoming deadlines
#+BEGIN: org-ql-table :query (and (tags "assignment") (not (property "grade")) (deadline :from today :to +30)) :columns (file (property "deadline") (property "class")) :from "~/org/uni/"
#+END:

* Today's schedule
[[id:...][Today's daily note]]
```

---

## Phase 3d — Google Calendar sync (replaces calcurse)

`org-gcal` syncs between org-agenda and Google Calendar. Setup requires a Google
Cloud OAuth2 project — similar to what calcurse-caldav needed.

```elisp
(use-package org-gcal
  :custom
  (org-gcal-client-id     "YOUR_CLIENT_ID")
  (org-gcal-client-secret "YOUR_CLIENT_SECRET")
  (org-gcal-fetch-file-alist
   '(("tidemanus@gmail.com" . "~/org/gcal.org")))
  :config
  ;; Sync on org-agenda open
  (add-hook 'org-agenda-mode-hook 'org-gcal-fetch))
```

**Important**: `org-gcal-client-id` and `org-gcal-client-secret` must NOT be in
git. Store them in `~/.authinfo.gpg` (encrypted) and reference via `auth-source`:
```elisp
;; Instead of hardcoding, let auth-source read ~/.authinfo.gpg:
(setq org-gcal-client-id
  (auth-source-pick-first-password :host "org-gcal" :user "client-id"))
(setq org-gcal-client-secret
  (auth-source-pick-first-password :host "org-gcal" :user "client-secret"))
```

**Setup steps** (one-time, after rebuild):
1. Create a Google Cloud project → enable Calendar API → create OAuth2 credentials
2. Download `credentials.json` → extract client_id and client_secret
3. Write to `~/.authinfo.gpg`:
   ```
   machine org-gcal login client-id password YOUR_CLIENT_ID
   machine org-gcal login client-secret password YOUR_CLIENT_SECRET
   ```
4. Run `M-x org-gcal-fetch` — browser opens for OAuth approval
5. Events appear in `~/org/gcal.org`, visible in org-agenda

---

## Phase 3e — PDF viewing (pdf-tools)

```elisp
(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  :hook (pdf-view-mode . (lambda ()
    (display-line-numbers-mode -1)
    (olivetti-mode -1))))  ; no centering in PDF view

;; Evil bindings for PDF navigation
(evil-define-key 'normal pdf-view-mode-map
  "j"   'pdf-view-next-line-or-next-page
  "k"   'pdf-view-previous-line-or-previous-page
  "J"   'pdf-view-next-page
  "K"   'pdf-view-previous-page
  "gg"  'pdf-view-first-page
  "G"   'pdf-view-last-page
  "+"   'pdf-view-enlarge
  "-"   'pdf-view-shrink
  "H"   'pdf-view-fit-height-to-window
  "W"   'pdf-view-fit-width-to-window)
```

**Note**: pdf-tools requires a native compiled component. With nix this is handled
automatically — the `pdf-tools` package in nixpkgs includes the compiled `epdfinfo`
binary. No `pdf-tools-install` call needed at runtime; remove it if nixpkgs handles
compilation.

---

## Phase 3f — File browsing sidebar (replaces Obsidian file tree)

Since you navigate primarily by folder structure, a persistent sidebar is important.
`dired-sidebar` gives you an always-visible file tree.

```elisp
(use-package dired-sidebar
  :commands dired-sidebar-toggle-sidebar
  :custom
  (dired-sidebar-width 30)
  (dired-sidebar-use-term-integration t)
  :config
  (evil-define-key 'normal dired-sidebar-mode-map
    "h"  'dired-sidebar-up-directory
    "l"  'dired-sidebar-find-file
    "j"  'next-line
    "k"  'previous-line
    "RET" 'dired-sidebar-find-file
    "q"  'dired-sidebar-hide-sidebar))
```

SPC binding:
```elisp
"e"  'dired-sidebar-toggle-sidebar  ; SPC e → toggle file tree
```

The sidebar root changes automatically to match the current `org-roam-directory`
or project. In "personal" perspective it shows `~/org/personal/`; in "uni"
perspective it shows `~/org/uni/`.

---

## Phase 4 — Org-roam (replaces Obsidian backlinks + folder structure)

### Core setup
```elisp
(use-package org-roam
  :custom
  (org-roam-directory "~/org")
  (org-roam-dailies-directory "daily/")
  (org-roam-db-location "~/.local/share/org-roam/org-roam.db")
  :config
  (org-roam-db-autosync-mode))
```

### Capture templates (replaces Templater folder templates)
```elisp
(setq org-roam-capture-templates
  '(;; Personal: concept note (replaces Concepts/ + Knowledge/)
    ("c" "concept" plain
     "* ${title}\n\n%?"
     :target (file+head "personal/concepts/${slug}.org"
                        "#+title: ${title}\n#+filetags: :concept:\n")
     :unnarrowed t)

    ;; Personal: essay
    ("e" "essay" plain "%?"
     :target (file+head "personal/essays/${slug}.org"
                        "#+title: ${title}\n#+filetags: :essay:\n#+date: %<%Y-%m-%d>\n")
     :unnarrowed t)

    ;; Personal: book (replaces Sources/Books/ + book template)
    ("b" "book" plain
     "#+author: %^{Author}\n#+year: %^{Year}\n#+status: reading\n\n* Reading Notes\n\n%?\n\n* Summary\n\n* Historical context"
     :target (file+head "personal/sources/books/${slug}.org"
                        "#+title: ${title}\n#+filetags: :book:source:\n")
     :unnarrowed t)

    ;; Personal: person (replaces People/ + People template)
    ("p" "person" plain
     ":PROPERTIES:\n:birthday: \n:context: \n:occupation: \n:phone: \n:email: \n:city: \n:group: \n:END:\n\n* Bio\n\n* Personal Notes\n\n* Topics we share"
     :target (file+head "personal/people/${slug}.org"
                        "#+title: ${title}\n#+filetags: :person:\n")
     :unnarrowed t)

    ;; Uni: class (replaces Classes/ + Classes template)
    ("u" "class" plain
     ":PROPERTIES:\n:year: %^{Year}\n:Q: %^{Quarter}\n:professor: %^{Professor}\n:code: %^{Code}\n:shorthand: %^{Shorthand}\n:END:\n\n* Lectures\n#+BEGIN: org-ql-table :query (and (property \"class\" \"${title}\") (tags \"lecture\")) :columns (file date (property \"lecture_number\"))\n#+END:\n\n* Assignments\n#+BEGIN: org-ql-table :query (and (property \"class\" \"${title}\") (tags \"assignment\")) :columns (file (property \"deadline\") (property \"grade\"))\n#+END:\n\n* Summary\n\n* Files\n"
     :target (file+head "uni/classes/${slug}.org"
                        "#+title: ${title}\n#+filetags: :uni:class:\n")
     :unnarrowed t)

    ;; Uni: lecture (replaces Lecture/ + Lecture template)
    ("l" "lecture" plain
     ":PROPERTIES:\n:class: %^{Class}\n:date: %^{Date}\n:lecture_number: %^{Number}\n:END:\n\n* Summary\n\n%?\n\n* Notes"
     :target (file+head "uni/lectures/${slug}.org"
                        "#+title: ${title}\n#+filetags: :uni:lecture:\n")
     :unnarrowed t)

    ;; Uni: assignment (replaces Assignments/ + Assignments template)
    ("a" "assignment" entry
     "* TODO %^{Title}\n:PROPERTIES:\n:class: %^{Class}\n:deadline: %^{Deadline}\n:type: %^{Type}\n:grade: \n:END:"
     :target (file "uni/assignments/assignments.org")
     :unnarrowed t)

    ;; Quick inbox capture
    ("i" "inbox" entry (file "~/org/inbox.org")
     "* %?\n  %U")))
```

### Daily notes (replaces personal Dailies/ and uni loose session notes)
```elisp
(setq org-roam-dailies-capture-templates
  '(("d" "daily" entry "* %<%H:%M> %?"
     :target (file+head "%<%Y-%m-%d>.org"
                        "#+title: %<%Y-%m-%d>\n#+filetags: :daily:\n"))))
```

---

## Phase 5 — Org-ql (replaces Dataview)

### Core setup
```elisp
(use-package org-ql
  :after org)
```

### Replacing the key Dataview queries:

**Uni MOC — all classes** (replaces `table year, Q from "Classes" sort year, Q`):
```elisp
(org-ql-search "~/org/uni/classes/"
  '(tags "class")
  :sort '(property "year"))
```
As a named agenda view (SPC a → c → classes):
```elisp
(add-to-list 'org-agenda-custom-commands
  '("uc" "All uni classes"
    (org-ql-block '(tags "class")
                  ((org-ql-block-header "Classes")
                   (org-agenda-files '("~/org/uni/classes/"))))))
```

**Uni MOC — upcoming deadlines** (replaces `where !grade and date > today sort date asc`):
```elisp
(add-to-list 'org-agenda-custom-commands
  '("ud" "Upcoming deadlines"
    ((org-ql-block '(and (tags "assignment")
                         (not (property "grade"))
                         (deadline :from today))
                   ((org-ql-block-header "Assignments due")
                    (org-agenda-files '("~/org/uni/assignments/")))))))
```

**Class page — lectures by class** (org-ql dynamic block, lives inside the class .org file):
The template above already inserts:
```org
#+BEGIN: org-ql-table :query (and (property "class" "X") (tags "lecture")) ...
#+END:
```
Update with `C-c C-c` on the block, or `org-dblock-update`.

### Global custom agenda (your main dashboard — replaces Uni MOC):
```elisp
(setq org-agenda-custom-commands
  '(("d" "Dashboard"
     ((agenda "" ((org-agenda-span 7)))
      (org-ql-block '(and (tags "assignment")
                          (not (property "grade"))
                          (deadline :from today :to +30))
                    ((org-ql-block-header "Assignments (30 days)")
                     (org-agenda-files '("~/org/uni/"))))
      (org-ql-block '(todo "TODO")
                    ((org-ql-block-header "Inbox")
                     (org-agenda-files '("~/org/inbox.org"))))))))
```

---

## Phase 6 — Typst setup (replaces typst-mate)

```elisp
(use-package typst-ts-mode
  :custom
  (typst-ts-mode-watch-options "--open")  ; auto-open PDF on watch
  :hook
  (typst-ts-mode . eglot-ensure))  ; LSP via tinymist

;; Tinymist (Typst LSP) is in common.nix packages
;; eglot picks it up automatically for typst-ts-mode
```

**Workflow for Typst files:**
1. Open `.typ` file in Emacs → typst-ts-mode activates
2. `M-x typst-ts-mode-watch-start` → typst compiles on save, PDF auto-refreshes
3. Or: use a split window — left: `.typ` file, right: PDF in zathura

**SPC keybindings to add for Typst:**
```elisp
(general-define-key
  :keymaps 'typst-ts-mode-map
  :states '(normal)
  "SPC m w" 'typst-ts-mode-watch-start
  "SPC m W" 'typst-ts-mode-watch-stop
  "SPC m p" '(lambda () (interactive)
               (find-file (concat (file-name-sans-extension buffer-file-name) ".pdf"))))
```

---

## Phase 7 — Elfeed + YouTube (replaces RSS dashboard)

### Setup
```elisp
(use-package elfeed
  :custom
  (elfeed-db-directory "~/.local/share/elfeed")
  :bind ("C-x w" . elfeed))

(use-package elfeed-org
  :after elfeed
  :config
  (elfeed-org)
  :custom
  (rmh-elfeed-org-files '("~/.config/emacs/elfeed.org")))

(use-package elfeed-tube
  :after elfeed
  :config (elfeed-tube-setup)
  :bind (:map elfeed-show-mode-map
         ("F" . elfeed-tube-fetch)
         ([remap save-buffer] . elfeed-tube-save)
         :map elfeed-search-mode-map
         ("F" . elfeed-tube-fetch)
         ([remap save-buffer] . elfeed-tube-save)))
```

### `home/dotfiles/emacs/elfeed.org` — feed list
```org
* Feeds
** [[https://www.youtube.com/feeds/videos.xml?channel_id=CHANNEL_ID][Channel Name]]  :elfeed:
** [[https://example.com/rss][Some RSS Feed]]  :elfeed:
```
Add your YouTube channels by replacing `CHANNEL_ID`.

**elfeed-tube workflow:**
- `F` on a YouTube entry → fetches transcript + description
- `C-c C-o` → open in mpv directly from elfeed
- Better than Obsidian rss-dashboard because you can read, queue, and play without leaving Emacs.

---

## Phase 8 — Lecture → Summary → Knowledge workflow

This is your core study workflow: write per-lecture notes, combine them into a class
summary, then extract the understanding into your personal knowledge vault.
`org-transclusion` is built for exactly this.

### How org-transclusion works

A transclusion is a live embed of content from another file. You write:
```org
#+transclude: [[file:../lectures/aQM-lecture-01.org::*Notes]] :level 2
```
And Emacs renders the "Notes" section of that lecture file inline in your summary.
When you edit the transclusion, you're editing the source lecture file. When you
update the source, the summary updates on next refresh.

This means the class summary is not a separate copy — it's a structured view over
the lecture files, with your own synthesis written around the transcluded sections.

### Setup
```elisp
(use-package org-transclusion
  :after org
  :hook (org-mode . org-transclusion-mode)
  :bind (:map org-mode-map
         ("C-c t a" . org-transclusion-add)
         ("C-c t A" . org-transclusion-add-all)
         ("C-c t r" . org-transclusion-refresh-all)))
```

### Class summary file structure (replaces restructured copy-paste)
```org
#+title: Advanced Quantum Mechanics — Summary
#+filetags: :uni:summary:

* Overview
[Your own synthesis here]

* Lecture 1 — [Topic]
#+transclude: [[file:../lectures/aQM-lecture-01.org::*Notes]] :level 2

* Lecture 2 — [Topic]
#+transclude: [[file:../lectures/aQM-lecture-02.org::*Notes]] :level 2

* Key concepts
[Your synthesis — written here, not transcluded]
```

With `org-transclusion-add-all` (bound to `C-c t A`), all `#+transclude:` blocks
render live. Toggle off with `C-c t a` to see the raw links.

**Workflow in practice:**
1. After each lecture: write notes in `uni/lectures/aQM-lecture-N.org`
2. Summary file: add a new `#+transclude:` block pointing to that lecture's Notes section
3. Write your synthesis between the blocks
4. The copy-paste step is eliminated — the lecture content is always live in the summary

### Personal knowledge file (the extraction step)

When a class connects to your personal interests ("Varies a lot"):

- If close to an existing concept: open the concept file, add an org-roam link back
  to the uni summary, add your personal synthesis. The backlinks panel shows the
  connection from uni → personal.
- If it becomes a standalone concept: create a new concept node with `SPC n c`.
  Transclude the relevant summary section there too, if you want the content present.
  Or just link: `[[id:...][Advanced Quantum Mechanics Summary]]`

The key shift from Obsidian: instead of copying text, you either link or transclude.
The original content stays in one place; references point to it. This keeps personal
and uni knowledge connected rather than duplicated.

### SPC keybindings for this workflow
```elisp
;; Add to SPC n (notes) prefix:
"nt" 'org-transclusion-add          ; add a transclusion at point
"nT" 'org-transclusion-add-all      ; render all transclusions in buffer
"nR" 'org-transclusion-refresh-all  ; refresh after source changes
```

---

## Phase 9 — Book library (replaces Obsidian Canvas book grid)

The Obsidian Canvas book grid (cover image + metadata at a glance) is one of
the things Obsidian genuinely does well. Emacs won't match it visually, but
`citar` provides a much more powerful underlying system, with a visual component.

### What citar gives you

```elisp
(use-package citar
  :custom
  (citar-bibliography '("~/org/library.bib"))  ; single .bib file, Syncthing-synced
  (citar-notes-paths '("~/org/personal/sources/books/"
                       "~/org/personal/sources/papers/"))
  (citar-open-always-create-notes t))

(use-package citar-org
  :after (citar org)
  :custom (org-cite-insert-processor 'citar)
          (org-cite-follow-processor 'citar)
          (org-cite-activate-processor 'citar))

(use-package org-roam-bibtex
  :after (org-roam citar)
  :config (org-roam-bibtex-mode))
```

### library.bib as the source of truth

Every book and paper you read gets an entry in `~/org/library.bib`. This is a
standard BibTeX file — manageable with `citar`, usable in Typst documents directly.

When you open a citar entry, it either finds the existing org-roam note or creates
one using the book capture template. The note gets the title, author, year from the
.bib entry automatically.

### The book grid equivalent

Org-mode can display images inline. Create `~/org/personal/sources/books/index.org`:

```org
#+title: Books
#+STARTUP: inlineimages

* Currently reading
** Landau & Lifshitz — Mechanics
   [[file:covers/landau-mechanics.jpg]]
   :PROPERTIES:
   :status: reading
   :author: Landau, Lifshitz
   :year: 1976
   :END:
   [[id:...][Reading notes]]
```

Toggle image display with `C-c C-x C-v` (`org-toggle-inline-images`).
Not a pixel-perfect grid, but functional — and you can sort, filter, and search
in ways Obsidian Canvas can't.

For an actual grid view: `citar` has a `citar-open` interface that lists all
entries with metadata in a filterable minibuffer. Fast search across your entire
library by title, author, year, or tag.

### YouTube RSS feed generation

Export your YouTube subscriptions via Google Takeout (takeout.google.com →
select only "YouTube and YouTube Music" → "subscriptions"). You get a
`subscriptions.csv`. Convert to elfeed.org format:

```bash
#!/usr/bin/env bash
echo "* YouTube"
tail -n +2 subscriptions.csv | while IFS=, read -r id url name; do
  clean="${name//\"/}"
  echo "** [[$url][$clean]]  :elfeed:youtube:"
done
```

Run once, paste output into `home/dotfiles/emacs/elfeed.org`.

---

## Phase 11 — File tree for class pages (replaces dataviewjs)

The dataviewjs filesystem tree was nice-to-have. Replace with a simple function:

```elisp
(defun uni-open-class-files ()
  "Open dired on the uni master folder for the current class."
  (interactive)
  (let ((class-name (org-entry-get nil "class" t)))
    (if class-name
        (dired (concat "/home/thijmen/Documents/BACKUP/Uni/Master/" class-name))
      (dired "/home/thijmen/Documents/BACKUP/Uni/Master/"))))
```

Add to SPC bindings when in org-mode class files:
```elisp
"SPC m f" 'uni-open-class-files
```

---

## Phase 12 — Day planning (replaces day-planner)

For uni: the org-agenda time-grid shows your schedule for today with time blocks.

```elisp
(setq org-agenda-time-grid
  '((daily today require-timed)
    (800 1000 1200 1400 1600 1800 2000)
    "......"
    "────────────────"))

;; Schedule assignments: add SCHEDULED: <date time> to any assignment TODO
;; They then appear in org-agenda time-grid
```

For deeper time-blocking, `org-timeblock` creates a visual block schedule.
Check if `pkgs.emacsPackages.org-timeblock` exists in nixpkgs 26.05; if not, skip.

---

## Phase 13 — Conversion: Markdown → Org

**Tool**: `pandoc` — already in common.nix packages (or add it).

### Conversion script
```bash
#!/usr/bin/env bash
# convert_vault.sh — run once to migrate both vaults
# Run from: /home/thijmen/

PERSONAL_IN="Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure"
UNI_IN="Documents/BACKUP/Uni/Obsidian/Uni"
OUT_BASE="org"

convert_dir() {
  local src="$1" dst="$2"
  mkdir -p "$dst"
  find "$src" -name "*.md" -not -path "*/.obsidian/*" | while read -r md; do
    rel="${md#$src/}"
    org="$dst/${rel%.md}.org"
    mkdir -p "$(dirname "$org")"
    pandoc --from=markdown --to=org \
           --wrap=none \
           "$md" -o "$org"
    echo "converted: $org"
  done
}

convert_dir "$PERSONAL_IN" "$OUT_BASE/personal"
convert_dir "$UNI_IN"      "$OUT_BASE/uni"
```

### What pandoc handles automatically:
- YAML frontmatter → org `:PROPERTIES:` drawer
- `**bold**`, `*italic*` → `*bold*`, `/italic/`
- `# Headings` → `* Headings`
- `[[wikilinks]]` → broken links (needs post-processing — see below)
- Code blocks → `#+begin_src ... #+end_src`
- Tables → org tables
- `> blockquotes` → `#+begin_quote ... #+end_quote`

### Post-conversion: fix wikilinks
Obsidian `[[Note Name]]` links become org-roam `[[id:...][Note Name]]` links.
Run org-roam's import after conversion:
```elisp
;; After placing all .org files in ~/org/:
M-x org-roam-db-sync  ; builds the database
;; Then use org-roam-unlinked-references to find/fix broken links
```

### What to do with Dataview blocks:
After conversion, dataview blocks become literal code blocks:
```org
#+begin_src dataview
table class, lecture_number from "Lecture" ...
#+end_src
```
Replace these manually with org-ql dynamic blocks (see Phase 5).
Do this one class file at a time — it's a few hours of work total.

---

## Phase 14 — Testing checklist

After rebuild:

**Core:**
- [ ] `emacs` launches, Stylix Ukiyo theme applied
- [ ] Evil mode: hjkl movement, `dd`, `yy`, `/` search, `SPC` opens which-key
- [ ] `SPC n f` finds org-roam nodes
- [ ] `SPC g g` opens magit
- [ ] `SPC a` opens org-agenda

**Notes:**
- [ ] `SPC n c` opens capture menu, templates listed (concept/essay/lecture/etc.)
- [ ] Create a new lecture note — frontmatter properties populated
- [ ] Create a new class note — org-ql dynamic block present
- [ ] `SPC n b` shows backlinks panel
- [ ] `SPC n g` opens org-roam graph in browser

**Typst:**
- [ ] Open a `.typ` file → typst-ts-mode activates, syntax highlighting works
- [ ] eglot connects to tinymist (check with `M-x eglot`)
- [ ] `typst-ts-mode-watch-start` compiles and opens PDF

**Elfeed:**
- [ ] `SPC r` opens elfeed
- [ ] Feeds load from elfeed.org
- [ ] YouTube entry: `F` fetches description
- [ ] Playing video: `C-c C-o` launches mpv

**Day planning:**
- [ ] `SPC a d` shows dashboard agenda
- [ ] Upcoming assignments appear in deadline section
- [ ] SCHEDULED items appear in time-grid

**Math rendering:**
- [ ] Type `$\int_0^1 f(x)\,dx$` in an org buffer — moves cursor away → renders as image
- [ ] `C-c C-x C-l` renders all fragments in buffer
- [ ] Math visible at correct scale (not too small)

**Workspaces:**
- [ ] `SPC TAB p` switches to personal perspective, opens dashboard.org
- [ ] `SPC TAB u` switches to uni perspective, opens uni/dashboard.org
- [ ] Buffer lists are separate between perspectives
- [ ] `SPC e` toggles dired-sidebar with correct root per perspective

**PDF:**
- [ ] Open a `.pdf` file — pdf-view-mode activates
- [ ] `j/k` scroll, `J/K` change pages, `H/W` fit to window

**Calendar:**
- [ ] `M-x org-gcal-fetch` opens browser for OAuth (first time only)
- [ ] After auth: events appear in `~/org/gcal.org`
- [ ] Events visible in `SPC a` org-agenda

**Misc:**
- [ ] `jinx-mode` active in org-mode (spell check — test with a Dutch word)
- [ ] `mixed-pitch-mode` applied (serif/sans for prose, mono for code blocks)
- [ ] `olivetti-mode` centers org buffer
- [ ] Tables render nicely (org-modern)

---

## Remaining open questions

- [ ] **org-timeblock vs time-grid**: org-agenda time-grid is planned. If you want
      a visual drag-and-drop schedule, add `org-timeblock`. Check if it's in nixpkgs 26.05.
- [ ] **org-gcal credentials**: you'll need to create a Google Cloud project and enable
      the Calendar API. The OAuth2 setup is the same as for calcurse-caldav.
      Credentials go in `~/.authinfo.gpg`, NOT in the nix config.
- [ ] **People notes**: include the capture template but mark as low-priority.
      Decide whether to structure by group (friends/colleagues/professors) when you
      start using them.
- [ ] **Neovim vs Emacs for code**: start with coexistence. If Emacs eglot + Python
      feels good after a month of use, consider switching fully. No need to decide now.
- [ ] **SPC keybinding parity**: before writing final init.el, read
      `home/dotfiles/neovim/init.lua` and map identical SPC bindings in Emacs.
- [ ] **Conversion timing**: run pandoc conversion on a copy of both vaults first,
      verify org-roam DB builds correctly, then switch. Keep Obsidian open until satisfied.
- [ ] **Thesis**: capture template is included. Become active when thesis work starts.
