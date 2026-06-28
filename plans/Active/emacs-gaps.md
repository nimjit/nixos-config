# Emacs gaps — Dashboards, YouTube, Email, Music, Messages

Messages (Wasabi) has its own detailed plan at `plans/Active/wasabi.md`; it's
included here for ordering and cross-reference.

## Priority order (suggested)

1. **YouTube** — small, self-contained fix; quick win
2. **Music** — replace EMMS with mpdel; cleaner architecture
3. **Dashboards** — vault dashboard + uni dashboard; the greeting is mostly done
4. **Email** — mu4e; the maildir already exists so it's less work than it looks
5. **Messages** — Wasabi + wuzapi; most research needed, do last

---

## 1. YouTube — fix elfeed-tube

### What's broken

elfeed and elfeed-org appear to load. elfeed-tube is configured but not rendering
correctly. "Not working" likely means one of:

- Feeds haven't been fetched yet (first run requires `M-x elfeed-update`)
- elfeed-tube needs `yt-dlp` available on PATH and it isn't
- The `elfeed-tube-setup` hook isn't firing because elfeed-tube loads after elfeed

### Debug steps (do these first)

1. Open elfeed: `M-x elfeed`
2. Run `M-x elfeed-update` and wait. Do entries appear?
   - If no entries: the org file isn't being read. Check `rmh-elfeed-org-files` points
     to the right path (`C-h v rmh-elfeed-org-files`).
   - If entries appear but YouTube ones are missing: check the elfeed.org UULF URLs
     are syntactically correct.
3. Open a YouTube entry. Press `F` (`elfeed-tube-fetch`). Does it fetch a description?
   - If error about yt-dlp: see fix below.
   - If it fetches: the issue is display, not fetch.

### Fix A — add yt-dlp to packages

elfeed-tube uses yt-dlp to fetch video metadata. Add it to `home/default.nix` or
`modules/common.nix` (it may already be present for mpv):

```nix
home.packages = with pkgs; [
  yt-dlp
  # ...existing packages...
];
```

Then rebuild.

### Fix B — load order in config.org

If elfeed-tube's hooks aren't attaching, it may be loading before elfeed is ready.
The `:after elfeed` in the use-package form should handle this, but double-check
the elfeed-tube block is actually `:after elfeed` and not `:after elfeed-org`.

Current block (verify this is in config.org):
```elisp
(use-package elfeed-tube
  :after elfeed
  :config
  (elfeed-tube-setup)
  (setq elfeed-tube-mpv-options '("--no-terminal")))
```

### Fix C — keybindings

Once fetching works, add these to the elfeed-tube config block:

```elisp
(evil-define-key 'normal elfeed-show-mode-map
  "F"  #'elfeed-tube-fetch          ; fetch description for current entry
  "C-m" #'elfeed-tube-mpv-play)     ; open in mpv (C-m = Enter)
```

### What to expect when working

- elfeed shows a text list of entries (no thumbnails, no card layout)
- `F` on a YouTube entry fetches the description inline
- `Enter` (or the bound key) opens the video in mpv
- Filter by tag: `s` in elfeed then type `+youtube` or `+physics` etc.

This is a text experience, not yt-feed's card layout. Whether it's good enough
for daily use is an open question — if not, keep yt-feed running alongside.

---

## 2. Music — switch to mpdel

### Why mpdel instead of fixing EMMS

MPD is already running, managed by Home Manager, pointed at `~/Music/`. EMMS
reimplements playback from scratch and its browser interface doesn't match the
rmpc mental model. `mpdel` is an Emacs client for the MPD protocol — it talks to
the running MPD daemon directly, exactly like rmpc does, but from inside Emacs.
Lighter, more familiar concept.

### Packages — home/emacs.nix

Add `mpdel` and its dependency `libmpdel` to extraPackages:

```nix
libmpdel    # MPD protocol library (mpdel depends on this)
mpdel       # Emacs MPD client
```

Remove or keep `emms` (can coexist, but no longer the primary interface).

### Configuration — config.org

Add a `* Music (mpdel)` section (replace or supplement the EMMS block):

```elisp
(use-package libmpdel
  :config
  ;; MPD is on localhost:6600 by default — matches home/mpd.nix
  (setq libmpdel-hostname "localhost"
        libmpdel-port 6600))

(use-package mpdel
  :after libmpdel
  :config
  (mpdel-mode)   ; global minor mode; adds keybindings to mpdel buffers

  (evil-define-key 'normal mpdel-browser-mode-map
    "j"   #'mpdel-browser-next-line
    "k"   #'mpdel-browser-previous-line
    "l"   #'mpdel-browser-open-entry     ; enter artist/album/track
    "h"   #'mpdel-browser-back
    "g"   (lambda () (interactive) (goto-char (point-min)))
    "G"   (lambda () (interactive) (goto-char (point-max)))
    "a"   #'mpdel-browser-add            ; add to queue
    "q"   #'bury-buffer
    "SPC" #'mpdel-core-toggle-play-pause)

  (evil-define-key 'normal mpdel-playlist-mode-map
    "j"   #'mpdel-playlist-next-line
    "k"   #'mpdel-playlist-previous-line
    "d"   #'mpdel-playlist-remove-from-queue
    "SPC" #'mpdel-core-toggle-play-pause
    "q"   #'bury-buffer))

;; Leader bindings (replace existing EMMS bindings)
(spc! "m m" '(mpdel-browser-open-artists :wk "music browser")
      "m SPC" '(mpdel-core-toggle-play-pause :wk "pause / play")
      "m n" '(mpdel-core-next :wk "next track")
      "m p" '(mpdel-core-previous :wk "prev track")
      "m q" '(mpdel-browser-open-current-playlist :wk "queue"))
```

**Note**: mpdel function names may differ slightly — check with `C-h f mpdel-`
after loading the package and adjust the key bindings above.

### Dashboard button

Update `my/dash-music` in the Dashboard section of config.org:

```elisp
(defun my/dash-music ()
  (interactive)
  (mpdel-browser-open-artists))   ; or mpdel-browser-open — verify name
```

---

## 3. Email — mu4e

### Why this is easier than it looks

The full maildir sync infrastructure is **already running**:
- `mbsync` syncs Gmail → `~/Mail/Gmail/` every 5 minutes
- `msmtp` handles outgoing mail
- App passwords are in lpass

mu4e just needs `mu` (the indexer) and Emacs config that points at `~/Mail/`.
No new sync setup needed.

### Packages — home/emacs.nix and common.nix

Add `mu` to system packages (it includes mu4e):

```nix
# in modules/common.nix or home/default.nix:
environment.systemPackages = with pkgs; [
  mu
  # ...existing...
];
```

`mu4e` ships inside the `mu` package as an Emacs package. In `home/emacs.nix`,
add it to extraPackages:

```nix
mu4e   # or: (pkgs.mu.override { emacs = pkgs.emacs-pgtk; })
# Check: nix-env -qaP | grep '^nixpkgs\.mu4e'
# If not a standalone package, mu4e comes bundled with mu — load it via :load-path
```

**Alternative**: if mu4e isn't a standalone nixpkgs emacs package, add the load
path manually in config.org:
```elisp
(add-to-list 'load-path (concat (string-trim (shell-command-to-string "mu4e-meta")) "/share/emacs/site-lisp/mu4e"))
```
Or use `(require 'mu4e)` after adding `${pkgs.mu}/share/emacs/site-lisp/mu4e` to
`home.sessionVariables` or the emacs `load-path` via `extraConfig` in emacs.nix.

### First-time setup (run once in terminal)

```bash
mu init --maildir=~/Mail --my-address=tidemanus@gmail.com --my-address=thijmen.nouwens@gmail.com
mu index
```

After the initial index, mu updates automatically when mbsync syncs.

### Configuration — config.org

Add a `* Email (mu4e)` section:

```elisp
(use-package mu4e
  :ensure nil   ; comes with the mu system package, not from ELPA

  :init
  (setq mu4e-maildir       "~/Mail"
        mu4e-get-mail-command "mbsync -a"   ; mu4e can trigger a sync
        mu4e-update-interval 300            ; sync every 5 min (matches mbsync timer)
        mu4e-compose-reply-to-address "tidemanus@gmail.com"
        mu4e-user-mail-address-list '("tidemanus@gmail.com" "thijmen.nouwens@gmail.com"))

  ;; Folder mapping for Gmail (Dutch folder names — see email.md)
  (setq mu4e-drafts-folder  "/Gmail/[Gmail]/Concepten"
        mu4e-sent-folder    "/Gmail/[Gmail]/Verzonden berichten"
        mu4e-trash-folder   "/Gmail/[Gmail]/Prullenbak"
        mu4e-refile-folder  "/Gmail/[Gmail]/Alle e-mail")

  ;; Don't save sent mail locally — Gmail already does it server-side
  (setq mu4e-sent-messages-behavior 'delete)

  :config
  ;; Sending via msmtp (already configured)
  (setq message-send-mail-function #'message-send-mail-with-sendmail
        sendmail-program (executable-find "msmtp")
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-sendmail-f-is-evil t)

  ;; Evil keybindings for the headers view
  (evil-define-key 'normal mu4e-headers-mode-map
    "j"   #'mu4e-headers-next
    "k"   #'mu4e-headers-prev
    "l"   #'mu4e-headers-view-message
    "d"   #'mu4e-headers-mark-for-delete
    "u"   #'mu4e-headers-mark-for-unmark
    "r"   #'mu4e-compose-reply
    "m"   #'mu4e-compose-new
    "g"   #'mu4e-headers-first
    "G"   #'mu4e-headers-last
    "q"   #'mu4e-quit
    "?"   #'mu4e-display-manual)

  (evil-define-key 'normal mu4e-view-mode-map
    "j"   #'mu4e-view-headers-next
    "k"   #'mu4e-view-headers-prev
    "h"   #'mu4e-view-quit-message
    "r"   #'mu4e-compose-reply
    "R"   #'mu4e-compose-reply-all   ; check exact function name
    "q"   #'mu4e-view-quit-message)

  ;; Bookmarks
  (setq mu4e-bookmarks
        '((:name "Inbox"    :query "maildir:/Gmail/INBOX"       :key ?i)
          (:name "Unread"   :query "flag:unread AND NOT flag:trashed" :key ?u)
          (:name "Today"    :query "date:today..now"            :key ?t)))

  ;; Don't HTML-render by default — prefer plain text
  (setq mu4e-view-prefer-html nil
        mu4e-html2text-command "w3m -T text/html"))  ; w3m already available

;; Leader binding
(spc! "e" '(mu4e :wk "email"))
```

### Dashboard button

Update `my/dash-email` in the Dashboard section:

```elisp
(defun my/dash-email ()
  (interactive)
  (mu4e))
```

### Mail count in dashboard header

The dashboard currently reads unread count from Maildir directly via shell command.
This still works with mu4e since mbsync still writes to `~/Mail/`. No change needed.

---

## 4. Messages — Wasabi

See `plans/Active/wasabi.md` for the full plan. Summary:

- **wuzapi**: Go daemon (build with `pkgs.buildGoModule`), run as systemd user service
- **Wasabi**: Emacs package (check MELPA first, otherwise `trivialBuild`)
- Evil keybindings: add after loading; check evil-collection for existing entry
- Theme: override hardcoded faces if needed after first load

Do this last — needs the most research (repo coordinates, port, QR pairing flow).

---

## 5. Dashboards

### Context — three dashboards, not one

There are three distinct dashboards in the neovim setup:

1. **Greeting** (`my/dashboard`) — already implemented in Emacs. Shows date, weather,
   fortune, timetable (khal + daily Schedule section), dailies checklist, deadlines,
   todos, project rotation, mail, messages. Missing: birthdays, weight chart.

2. **Vault dashboard** (`my/dash-vault-work`) — currently just opens dired on the vault.
   In neovim this is a full dashboard. Needs to be built.

3. **Uni dashboard** (`my/dash-uni-work`) — currently just opens dired on uni.
   In neovim this is a full dashboard. Needs to be built.

---

### 5a. Greeting dashboard — missing pieces

#### Birthdays

The neovim vault dashboard reads every `.md` file in `VAULT/People/`, parses YAML
frontmatter for a `birthday:` field (format: `YYYY-MM-DD` or `DD-MM-YYYY`), and
shows all people whose birthday falls this month.

Add to `my/dashboard` in config.org, in the right column, before Deadlines:

```elisp
(defun my/dash--birthdays ()
  "Return list of strings for people with birthdays this month."
  (let* ((people-dir (expand-file-name "People" my/dash-vault))
         (now (decode-time))
         (cur-month (nth 4 now))
         (cur-year  (nth 5 now))
         results)
    (dolist (file (directory-files people-dir t "\\.md$"))
      (with-temp-buffer
        (insert-file-contents file nil 0 1000)  ; read only first 1000 bytes
        (goto-char (point-min))
        (when (looking-at "---")
          (let ((fm-end (save-excursion
                          (forward-line)
                          (and (re-search-forward "^---$" nil t) (point)))))
            (when fm-end
              (let* ((fm-str (buffer-substring-no-properties (point-min) fm-end))
                     (bday   (and (string-match "^birthday:[[:space:]]*\\(.*\\)$" fm-str)
                                  (string-trim (match-string 1 fm-str))))
                     (name   (and (string-match "^name:[[:space:]]*\\(.*\\)$" fm-str)
                                  (string-trim (match-string 1 fm-str)))))
                (when (and bday (not (string-empty-p bday)))
                  (let* ((parts (split-string bday "-"))
                         (y (string-to-number (nth 0 parts)))
                         (m (string-to-number (nth 1 parts)))
                         (d (string-to-number (nth 2 parts)))
                         ;; handle DD-MM-YYYY vs YYYY-MM-DD
                         (year  (if (> y 31) y d))
                         (month (nth 1 parts))
                         (day   (if (> y 31) d y)))
                    (setq month (string-to-number month))
                    (when (= month cur-month)
                      (let* ((age  (- cur-year year))
                             (bday-ts (encode-time 0 0 12 day month cur-year))
                             (diff (/ (- (float-time bday-ts) (float-time)) 86400))
                             (when-str (cond ((and (>= diff 0) (< diff 1)) "today!")
                                            ((> diff 0) (format "in %d days" (ceiling diff)))
                                            (t (format "%d days ago" (floor (- diff)))))))
                        (push (format "%-28s  %s %2d   (%s, turning %d)"
                                      (or name (file-name-base file))
                                      (nth (1- month) '("Jan" "Feb" "Mar" "Apr" "May" "Jun"
                                                         "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
                                      day when-str age)
                              results)))))))))
    (sort results (lambda (a b)
                    (< (string-to-number (substring a 30 32))
                       (string-to-number (substring b 30 32)))))))
```

Insert in the right column of `my/dashboard`, after the Dailies checklist:

```elisp
(let ((bdays (my/dash--birthdays)))
  (when bdays
    (push "" right)
    (push (propertize "Birthdays" 'face 'font-lock-keyword-face) right)
    (dolist (b bdays) (push (concat "  " b) right))))
```

#### Weight chart

The neovim dashboard calls `plot-weights` (at `~/.local/bin/plot-weights`) which
generates `/tmp/weight-plot.png` and prints the path. Emacs can do the same:

```elisp
(defun my/dash--insert-weight-chart ()
  "Run plot-weights async; insert PNG into current buffer when done."
  (let ((buf (current-buffer)))
    (make-process
     :name "plot-weights"
     :command (list (expand-file-name "~/.local/bin/plot-weights")
                    "--cols" (number-to-string (- (window-width) 6)))
     :filter  #'ignore
     :sentinel (lambda (_proc _event)
                 (when (file-exists-p "/tmp/weight-plot.png")
                   (with-current-buffer buf
                     (let ((inhibit-read-only t))
                       (save-excursion
                         (goto-char (point-max))
                         (insert "\n")
                         (insert-image (create-image "/tmp/weight-plot.png" 'png nil
                                                     :max-width (- (window-width) 6)))
                         (insert "\n")))))))))
```

Call `(my/dash--insert-weight-chart)` at the end of `my/dashboard`, after
`(switch-to-buffer buf)`.

Add a weight logging command, bound to `w` in the dashboard:

```elisp
(defun my/dash-log-weight ()
  "Prompt for today's weight, append row to weights file."
  (interactive)
  (let* ((w (read-number "Weight (kg): "))
         (weights-file (expand-file-name
                        "Knowledge/Body & Movement/Bodybuilding/Stats/Weights list.md"
                        my/dash-vault))
         ;; Read existing entries to compute moving averages
         (entries '())
         (today (format-time-string "%Y-%m-%d")))
    (with-temp-buffer
      (insert-file-contents weights-file)
      (goto-char (point-min))
      (while (re-search-forward
              "| *\\([0-9-]+\\) *| *\\([0-9.]+\\) *|" nil t)
        (push (cons (match-string 1) (string-to-number (match-string 2))) entries)))
    (let* ((all (reverse entries))
           (now-ts (float-time))
           (ma (lambda (days)
                 (let* ((cutoff (- now-ts (* days 86400)))
                        (relevant (seq-filter
                                   (lambda (e)
                                     (>= (float-time (date-to-time (car e))) cutoff))
                                   all))
                        (all-w (mapcar #'cdr (append relevant (list (cons today w)))))
                        (sum (apply #'+ all-w)))
                   (/ sum (length all-w)))))
           (ma7  (funcall ma 7))
           (ma21 (funcall ma 21))
           (ma30 (funcall ma 30))
           (row  (format "| %s | %.1f | %.2f | %.2f | %.2f |"
                         today w ma7 ma21 ma30)))
      (with-current-buffer (find-file-noselect weights-file)
        (goto-char (point-max))
        (unless (bolp) (insert "\n"))
        (insert row "\n")
        (save-buffer)))
    (message "Logged %.1f kg on %s" w today)
    (my/dash--insert-weight-chart)))
```

Add `w` key to the dashboard local map (same location as the other `local-set-key` calls):

```elisp
(local-set-key (kbd "w") #'my/dash-log-weight)
;; and in the evil-define-key* loop:
("w" . my/dash-log-weight)
```

Also add `"w"` to the footer shortcuts list.

---

### 5b. Vault dashboard — new: `my/vault-dashboard`

This replaces `my/dash-vault-work` (currently just opens dired). It is a full
Emacs equivalent of `M.open_vault` in `dashboard.lua`.

Add a new `** Vault dashboard` sub-section in the `* Dashboard` block in config.org.

**Data sources (all elisp, reading the markdown vault directly):**

| Section | Source | What to parse |
|---------|--------|---------------|
| BIRTHDAYS THIS MONTH | `VAULT/People/*.md` | `birthday:` YAML frontmatter (same as greeting addition above) |
| CONTINUE | `find VAULT -name "*.md"` sorted by mtime, grouped by top-level folder | 3 most recently modified folders + most recent file in each |
| PROJECTS | `VAULT/Misc/ToDo.md` `## Projects` bullet list | Full list with today's index highlighted (same rotation formula as greeting) |
| RECENT DAILY NOTES | `VAULT/Dailies/` sorted by mtime | 5 most recent `.md` files, clickable |
| KNOWLEDGE | `VAULT/Knowledge/` subdirectories | Name + note count per subdir |
| WEIGHT CHART | `~/.local/bin/plot-weights` | Run as async process, render PNG inline |

**Helper — CONTINUE section:**

```elisp
(defun my/dash--recent-vault-folders (n)
  "Return N most recently modified top-level vault folders."
  (let* ((cmd (format "find %s -name '*.md' -not -path '*/.obsidian/*' \
-not -path '*/Templates/*' -not -path '*/Attachments/*' \
-printf '%%T@ %%p\\n' 2>/dev/null | sort -rn | head -60"
                      (shell-quote-argument my/dash-vault)))
         (output (shell-command-to-string cmd))
         (by-folder (make-hash-table :test 'equal))
         (folder-mtime (make-hash-table :test 'equal)))
    (dolist (line (split-string output "\n" t))
      (when (string-match "^\\([0-9.]+\\) \\(.+\\)$" line)
        (let* ((mt   (string-to-number (match-string 1 line)))
               (path (match-string 2 line))
               (rel  (file-relative-name path my/dash-vault))
               (folder (car (split-string rel "/"))))
          (when (and folder (not (string-prefix-p "." folder)))
            (when (or (not (gethash folder folder-mtime))
                      (> mt (gethash folder folder-mtime)))
              (puthash folder mt folder-mtime)
              (puthash folder (cons path mt) by-folder))))))
    (let* ((folders (hash-table-keys folder-mtime))
           (sorted  (sort folders (lambda (a b)
                                    (> (gethash a folder-mtime)
                                       (gethash b folder-mtime))))))
      (seq-take
       (mapcar (lambda (f)
                 (let* ((entry (gethash f by-folder))
                        (path  (car entry))
                        (mt    (cdr entry))
                        (diff  (/ (- (float-time) mt) 86400))
                        (age   (cond ((< diff 1)  "today")
                                     ((< diff 2)  "yesterday")
                                     ((< diff 7)  (format "%d days ago" (floor diff)))
                                     ((< diff 14) "1 week ago")
                                     (t           (format "%d weeks ago"
                                                          (floor (/ diff 7)))))))
                   (list :folder f
                         :path   path
                         :name   (file-name-base path)
                         :age    age)))
               sorted)
       n))))
```

**Helper — Knowledge navigator:**

```elisp
(defun my/dash--knowledge-dirs ()
  "Return list of (name . count) for each Knowledge/ subdir."
  (let ((kdir (expand-file-name "Knowledge" my/dash-vault)))
    (mapcar (lambda (d)
              (let ((count (string-to-number
                            (string-trim
                             (shell-command-to-string
                              (format "find %s -name '*.md' 2>/dev/null | wc -l"
                                      (shell-quote-argument d)))))))
                (cons (file-name-nondirectory d) count)))
            (seq-filter #'file-directory-p
                        (directory-files kdir t "^[^.]")))))
```

**Full vault dashboard function:**

```elisp
(defun my/vault-dashboard ()
  "Open the personal vault dashboard."
  (interactive)
  (let* ((buf      (get-buffer-create "*Vault*"))
         (bdays    (my/dash--birthdays))
         (recent   (my/dash--recent-vault-folders 3))
         (todo-f   (expand-file-name "Misc/ToDo.md" my/dash-vault))
         (projects (my/dash--parse-section todo-f "Projects"))
         (proj-idx (when projects
                     (% (1- (string-to-number (format-time-string "%j")))
                        (length projects))))
         (dailies  (let ((dir (expand-file-name "Dailies" my/dash-vault)))
                     (seq-take
                      (sort (directory-files dir t "\\.md$")
                            (lambda (a b) (> (float-time (file-attribute-modification-time
                                                           (file-attributes a)))
                                            (float-time (file-attribute-modification-time
                                                           (file-attributes b))))))
                      5)))
         (know     (my/dash--knowledge-dirs)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq-local cursor-type nil)
        (insert "\n")
        (insert (propertize (concat "VAULT  ·  " (format-time-string "%A %-d %B %Y"))
                            'face 'font-lock-keyword-face) "\n\n")

        ;; BIRTHDAYS
        (insert (propertize "  BIRTHDAYS THIS MONTH\n" 'face 'font-lock-keyword-face))
        (if bdays
            (dolist (b bdays) (insert "    " b "\n"))
          (insert (propertize "    — none —\n" 'face 'shadow)))
        (insert "\n")

        ;; CONTINUE
        (insert (propertize "  CONTINUE\n" 'face 'font-lock-keyword-face))
        (if recent
            (dolist (r recent)
              (let ((text (format "  %-18s  %-32s  %s"
                                  (plist-get r :folder)
                                  (plist-get r :name)
                                  (plist-get r :age)))
                    (path (plist-get r :path)))
                (insert-text-button text
                  'action (lambda (_) (find-file path))
                  'face 'default
                  'mouse-face 'highlight
                  'follow-link t)
                (insert "\n")))
          (insert (propertize "    — none —\n" 'face 'shadow)))
        (insert "\n")

        ;; PROJECTS
        (when projects
          (insert (propertize "  PROJECTS\n" 'face 'font-lock-keyword-face))
          (let ((i 0))
            (dolist (p projects)
              (let ((marker (if (= i proj-idx)
                                (propertize "  ← today" 'face 'font-lock-keyword-face)
                              "")))
                (insert (format "    %d  %s%s\n" (1+ i) p marker)))
              (setq i (1+ i))))
          (insert "\n"))

        ;; RECENT DAILY NOTES
        (insert (propertize "  RECENT DAILY NOTES\n" 'face 'font-lock-keyword-face))
        (dolist (f dailies)
          (let ((name (file-name-base f))
                (path f))
            (insert "    ")
            (insert-text-button name
              'action (lambda (_) (find-file path))
              'face 'default
              'mouse-face 'highlight
              'follow-link t)
            (insert "\n")))
        (insert "\n")

        ;; KNOWLEDGE
        (insert (propertize "  KNOWLEDGE\n" 'face 'font-lock-keyword-face))
        (let ((row "") (max-w 68))
          (dolist (kd know)
            (let ((entry (format "%s (%d)" (car kd) (cdr kd))))
              (if (> (+ (length row) (length entry) 3) max-w)
                  (progn (insert "    " row "\n") (setq row entry))
                (setq row (if (string-empty-p row) entry
                            (concat row "  " entry))))))
          (unless (string-empty-p row) (insert "    " row "\n")))
        (insert "\n"))

      (read-only-mode 1)
      (goto-char (point-min))

      (use-local-map (make-sparse-keymap))
      (local-set-key (kbd "q") #'bury-buffer)
      (local-set-key (kbd "g") #'my/vault-dashboard)
      (local-set-key (kbd "f") (lambda () (interactive) (dired my/dash-vault)))
      (local-set-key (kbd "d") #'my/dash-today)
      (local-set-key (kbd "w") #'my/dash-log-weight)
      (when (fboundp 'evil-define-key*)
        (dolist (b '(("q" . bury-buffer)
                     ("g" . my/vault-dashboard)
                     ("d" . my/dash-today)
                     ("w" . my/dash-log-weight)))
          (evil-define-key* 'normal (current-local-map) (car b) (cdr b))
          (evil-define-key* 'motion (current-local-map) (car b) (cdr b)))))

    ;; Render weight chart async after buffer is visible
    (switch-to-buffer buf)
    (my/dash--insert-weight-chart))  ; defined in §5a above
  buf)
```

**Update `my/dash-vault-work`** (replace `dired` call):

```elisp
(defun my/dash-vault-work ()
  (interactive)
  (my/vault-dashboard))
```

**Keybindings inside vault dashboard:**

| Key | Action |
|-----|--------|
| `q` | bury buffer |
| `g` | refresh |
| `f` | dired on vault root |
| `d` | today's daily note |
| `w` | log weight (prompts, re-renders chart) |
| `RET` | follow link (clickable items) |

---

### 5c. Uni dashboard — new: `my/uni-dashboard`

Emacs equivalent of `M.open_uni` in `dashboard.lua`. Replaces `my/dash-uni-work`
(currently just opens dired on uni vault).

**Data sources:**

| Section | Source | What to parse |
|---------|--------|---------------|
| UPCOMING DEADLINES | `UNI/Deadines/*.md` | `date:`, `completed:`, `title:`, `class:`, `startTime:` YAML frontmatter; show only where `completed` is falsy and date ≥ today |
| ACTIVE ASSIGNMENTS | `UNI/Assignments/*.md` | `deadline:`, `grade:`, `class:`, `type:` YAML frontmatter; show only where `grade` is empty |
| COURSES | `UNI/Classes/*.md` | `year:`, `Q:`, `code:`, `shorthand:` YAML frontmatter; list all; each is clickable → course view |
| PLANNING | `UNI/Uni MOC.md` | Read `## Planning` section; render markdown pipe table as unicode box-drawing |

Note: the Deadlines folder in neovim is `UNI/Deadines/` (typo in original, one 'l').
Check whether this is actually the folder name: `ls "$UNI/Dead*"` first.

**`my/dash-uni` path** is already defined as a `defvar` in config.org — all paths below
use it.

**Helper — parse frontmatter from a markdown file:**
`my/dash--frontmatter` already exists in config.org but reads the *current* buffer.
For scanning directories, a version that takes a file path is needed:

```elisp
(defun my/dash--fm-from-file (file key)
  "Return frontmatter value of KEY from FILE, or nil."
  (with-temp-buffer
    (insert-file-contents file nil 0 2000)
    (goto-char (point-min))
    (when (looking-at "---")
      (let ((end (save-excursion (forward-line)
                                 (and (re-search-forward "^---$" nil t) (point)))))
        (when end
          (let ((fm (buffer-substring-no-properties (point-min) end)))
            (and (string-match (concat "^" (regexp-quote key)
                                       ":[[:space:]]*\\(.*\\)$")
                               fm)
                 (string-trim (match-string 1 fm)))))))))
```

**Helper — planning table (markdown → unicode box-drawing):**

```elisp
(defun my/dash--uni-planning ()
  "Read ## Planning section from Uni MOC.md; return list of rendered strings."
  (let* ((moc (expand-file-name "Uni MOC.md" my/dash-uni))
         lines in-section result)
    (when (file-exists-p moc)
      (with-temp-buffer
        (insert-file-contents moc)
        (goto-char (point-min))
        (while (not (eobp))
          (let ((line (buffer-substring-no-properties
                       (line-beginning-position) (line-end-position))))
            (cond
             ((string-match "^# Planning" line) (setq in-section t))
             ((and in-section (string-match "^# " line)) (setq in-section nil))
             (in-section (push line lines))))
          (forward-line))))
    (setq lines (nreverse lines))
    ;; Strip leading/trailing blank lines
    (while (and lines (string-blank-p (car lines))) (setq lines (cdr lines)))
    (while (and lines (string-blank-p (car (last lines)))) (setq lines (butlast lines)))
    ;; Render markdown pipe table as unicode
    (dolist (line lines)
      (cond
       ;; separator row: |---|---|  →  ├───┼───┤
       ((string-match "^|[[:space:]]*[-:]" line)
        (let* ((cells (split-string (string-trim line "|" "|") "|"))
               (parts (mapcar (lambda (c)
                                (make-string (+ (length (string-trim c)) 2) ?─))
                              cells)))
          (push (concat "├" (string-join parts "┼") "┤") result)))
       ;; data row
       ((string-match "^|" line)
        (let* ((cells (split-string (string-trim line "|" "|") "|"))
               (parts (mapcar (lambda (c) (concat " " (string-trim c) " ")) cells)))
          (push (concat "│" (string-join parts "│") "│") result)))
       (t (push line result))))
    (nreverse result)))
```

**Helper — upcoming deadlines:**

```elisp
(defun my/dash--uni-deadlines ()
  "Return sorted list of strings for upcoming uni deadlines."
  (let* ((dir (expand-file-name "Deadines" my/dash-uni))  ; note: one 'l' in source
         results)
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "\\.md$"))
        (let* ((completed (my/dash--fm-from-file file "completed"))
               (date-str  (my/dash--fm-from-file file "date"))
               (title     (my/dash--fm-from-file file "title"))
               (class     (my/dash--fm-from-file file "class"))
               (time-str  (my/dash--fm-from-file file "startTime")))
          (unless (or (string= completed "true")
                      (string= completed "yes")
                      (not date-str))
            (let* ((ts   (float-time (date-to-time
                                      (concat (my/dash--normalize-date date-str)
                                              " 12:00:00"))))
                   (diff (/ (- ts (float-time)) 86400)))
              (when (>= diff 0)
                (let* ((when-str (if (< diff 1) "TODAY"
                                   (format "in %d days" (ceiling diff))))
                       (label (if (and class title)
                                  (concat class " — " title)
                                (or title (file-name-base file))))
                       (time-part (if (and time-str (not (string-empty-p time-str)))
                                      (concat "  " time-str) "")))
                  (push (list :text  (format "%-44s  %s%s   (%s)"
                                             label date-str time-part when-str)
                              :diff  diff
                              :path  file)
                        results))))))))
    (sort results (lambda (a b) (< (plist-get a :diff) (plist-get b :diff))))))
```

**Helper — active assignments:**

```elisp
(defun my/dash--uni-assignments ()
  "Return sorted list of ungraded assignments."
  (let* ((dir (expand-file-name "Assignments" my/dash-uni))
         results)
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "\\.md$"))
        (let* ((grade    (my/dash--fm-from-file file "grade"))
               (deadline (my/dash--fm-from-file file "deadline"))
               (class    (my/dash--fm-from-file file "class"))
               (atype    (my/dash--fm-from-file file "type")))
          (when (or (null grade) (string-empty-p grade))
            (let* ((diff (and deadline
                               (/ (- (float-time
                                      (date-to-time
                                       (concat (my/dash--normalize-date deadline)
                                               " 12:00:00")))
                                     (float-time))
                                  86400)))
                   (when-str (cond ((null diff)   "?")
                                   ((< diff 1)    "TODAY")
                                   ((> diff 0)    (format "in %d days" (ceiling diff)))
                                   (t             (format "%dd ago" (floor (- diff)))))))
              (push (list :text  (format "%-35s  %-14s  %s   (%s)"
                                         (file-name-base file)
                                         (or atype "")
                                         (or deadline "")
                                         when-str)
                          :diff  (or diff 9999)
                          :path  file)
                    results))))))
    (sort results (lambda (a b) (< (plist-get a :diff) (plist-get b :diff))))))
```

**Helper — all courses:**

```elisp
(defun my/dash--uni-courses ()
  "Return list of course plists from UNI/Classes/."
  (let ((dir (expand-file-name "Classes" my/dash-uni)))
    (when (file-directory-p dir)
      (sort
       (mapcar (lambda (file)
                 (list :name      (file-name-base file)
                       :Q         (or (my/dash--fm-from-file file "Q") "")
                       :code      (or (my/dash--fm-from-file file "code") "")
                       :shorthand (or (my/dash--fm-from-file file "shorthand")
                                      (file-name-base file))
                       :path      file))
               (directory-files dir t "\\.md$"))
       (lambda (a b) (string< (plist-get a :Q) (plist-get b :Q)))))))
```

**Full uni dashboard function:**

```elisp
(defun my/uni-dashboard ()
  "Open the uni dashboard."
  (interactive)
  (let* ((buf         (get-buffer-create "*Uni*"))
         (deadlines   (my/dash--uni-deadlines))
         (assignments (my/dash--uni-assignments))
         (courses     (my/dash--uni-courses))
         (planning    (my/dash--uni-planning)))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq-local cursor-type nil)
        (insert "\n")
        (insert (propertize (concat "UNI  ·  " (format-time-string "%A %-d %B %Y"))
                            'face 'font-lock-keyword-face) "\n\n")

        ;; UPCOMING DEADLINES
        (insert (propertize "  UPCOMING DEADLINES\n" 'face 'font-lock-keyword-face))
        (if deadlines
            (dolist (d deadlines)
              (insert "    ")
              (insert-text-button (plist-get d :text)
                'action (lambda (_) (find-file (plist-get d :path)))
                'face 'default 'mouse-face 'highlight 'follow-link t)
              (insert "\n"))
          (insert (propertize "    — none —\n" 'face 'shadow)))
        (insert "\n")

        ;; ACTIVE ASSIGNMENTS
        (insert (propertize "  ACTIVE ASSIGNMENTS\n" 'face 'font-lock-keyword-face))
        (if assignments
            (dolist (a assignments)
              (insert "    ")
              (insert-text-button (plist-get a :text)
                'action (lambda (_) (find-file (plist-get a :path)))
                'face 'default 'mouse-face 'highlight 'follow-link t)
              (insert "\n"))
          (insert (propertize "    — none —\n" 'face 'shadow)))
        (insert "\n")

        ;; COURSES
        (insert (propertize "  COURSES\n" 'face 'font-lock-keyword-face))
        (if courses
            (dolist (c courses)
              (let ((text (format "    %-40s  Q%-8s  %s"
                                  (plist-get c :name)
                                  (plist-get c :Q)
                                  (plist-get c :code)))
                    (course c))
                (insert-text-button text
                  'action (lambda (_) (my/uni-course-view course))
                  'face 'default 'mouse-face 'highlight 'follow-link t)
                (insert "\n")))
          (insert (propertize "    — none —\n" 'face 'shadow)))
        (insert "\n")

        ;; PLANNING
        (insert (propertize "  PLANNING  (from Uni MOC)\n" 'face 'font-lock-keyword-face))
        (if planning
            (dolist (l planning) (insert "    " l "\n"))
          (insert (propertize "    — (no ## Planning section in Uni MOC.md) —\n" 'face 'shadow)))
        (insert "\n"))

      (read-only-mode 1)
      (goto-char (point-min))

      (use-local-map (make-sparse-keymap))
      (local-set-key (kbd "q") #'bury-buffer)
      (local-set-key (kbd "g") #'my/uni-dashboard)
      (local-set-key (kbd "f") (lambda () (interactive) (dired my/dash-uni)))
      (local-set-key (kbd "n") #'my/uni-new-lecture)
      (when (fboundp 'evil-define-key*)
        (dolist (b '(("q" . bury-buffer)
                     ("g" . my/uni-dashboard)
                     ("n" . my/uni-new-lecture)))
          (evil-define-key* 'normal (current-local-map) (car b) (cdr b))
          (evil-define-key* 'motion (current-local-map) (car b) (cdr b)))))

    (switch-to-buffer buf))
  buf)
```

**Update `my/dash-uni-work`:**

```elisp
(defun my/dash-uni-work ()
  (interactive)
  (my/uni-dashboard))
```

**Keybindings inside uni dashboard:**

| Key | Action |
|-----|--------|
| `q` | bury buffer |
| `g` | refresh |
| `f` | dired on uni vault root |
| `n` | new lecture note |
| `RET` | follow link (deadlines, assignments, courses all clickable) |

---

### 5d. Course view — `my/uni-course-view`

Clicking a course in the uni dashboard calls this. Shows all lecture notes for
that course, its ungraded assignments, and its summary file if one exists.

```elisp
(defun my/uni-course-view (course)
  "Open a buffer listing lecture notes and assignments for COURSE plist."
  (let* ((shorthand  (plist-get course :shorthand))
         (name       (plist-get course :name))
         (code       (plist-get course :code))
         (lec-dir    (expand-file-name "Lecture" my/dash-uni))
         lectures assignments summary-file)

    ;; Find lectures matching this course
    (dolist (file (directory-files lec-dir t "\\.md$"))
      (let ((cls   (my/dash--fm-from-file file "class"))
            (fname (file-name-base file)))
        (when (or (string= cls shorthand)
                  (string= cls name)
                  (string= cls code)
                  (string-prefix-p (downcase shorthand) (downcase fname)))
          (let* ((date-str (or (my/dash--fm-from-file file "date")
                               (and (string-match "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}" fname)
                                    (match-string 0 fname))
                               ""))
                 (title    (or (my/dash--fm-from-file file "title") fname)))
            (push (list :name title :date date-str :path file) lectures)))))
    (setq lectures (sort lectures (lambda (a b)
                                    (string< (plist-get a :date)
                                             (plist-get b :date)))))

    ;; Filter assignments for this course
    (dolist (a (my/dash--uni-assignments))
      (let ((file (plist-get a :path)))
        (when (string= (my/dash--fm-from-file file "class") shorthand)
          (push a assignments))))

    ;; Summary file
    (dolist (candidate (list (expand-file-name (concat name " Summary.md")
                                               (expand-file-name "Summary" my/dash-uni))
                             (expand-file-name (concat shorthand " Summary.md")
                                               (expand-file-name "Summary" my/dash-uni))))
      (when (and (file-exists-p candidate) (null summary-file))
        (setq summary-file candidate)))

    ;; Render buffer
    (let ((buf (get-buffer-create (format "*Course: %s*" name))))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert "\n")
          (insert (propertize (format "%s  (%s)\n\n" name code)
                              'face 'font-lock-keyword-face))

          (insert (propertize "  SUMMARY\n" 'face 'font-lock-keyword-face))
          (if summary-file
              (progn (insert "    ")
                     (insert-text-button (file-name-base summary-file)
                       'action (lambda (_) (find-file summary-file))
                       'face 'default 'mouse-face 'highlight 'follow-link t)
                     (insert "\n"))
            (insert (propertize "    — not found —\n" 'face 'shadow)))
          (insert "\n")

          (insert (propertize "  ASSIGNMENTS\n" 'face 'font-lock-keyword-face))
          (if assignments
              (dolist (a assignments)
                (insert "    ")
                (insert-text-button (plist-get a :text)
                  'action (lambda (_) (find-file (plist-get a :path)))
                  'face 'default 'mouse-face 'highlight 'follow-link t)
                (insert "\n"))
            (insert (propertize "    — none —\n" 'face 'shadow)))
          (insert "\n")

          (insert (propertize (format "  LECTURES  (%d)\n" (length lectures))
                              'face 'font-lock-keyword-face))
          (if lectures
              (let ((i 1))
                (dolist (l lectures)
                  (let ((text (format "  %2d.  %-13s  %s"
                                      i (plist-get l :date) (plist-get l :name)))
                        (path (plist-get l :path)))
                    (insert "    ")
                    (insert-text-button text
                      'action (lambda (_) (find-file path))
                      'face 'default 'mouse-face 'highlight 'follow-link t)
                    (insert "\n"))
                  (setq i (1+ i))))
            (insert (propertize "    — none —\n" 'face 'shadow))))

        (read-only-mode 1)
        (goto-char (point-min))
        (use-local-map (make-sparse-keymap))
        (local-set-key (kbd "q") #'bury-buffer)
        (local-set-key (kbd "n") #'my/uni-new-lecture)
        (when (fboundp 'evil-define-key*)
          (evil-define-key* 'normal (current-local-map) "q" #'bury-buffer)
          (evil-define-key* 'motion (current-local-map) "q" #'bury-buffer)))
      (switch-to-buffer buf))))
```

---

### 5e. New lecture helper — `my/uni-new-lecture`

```elisp
(defun my/uni-new-lecture ()
  "Create a new lecture note from template and open it."
  (interactive)
  (let* ((class    (read-string "Class shorthand: "))
         (date     (format-time-string "%Y-%m-%d"))
         (lec-dir  (expand-file-name "Lecture" my/dash-uni))
         (template (expand-file-name "Templates/Lecture.md" my/dash-uni))
         (target   (expand-file-name (concat class " " date ".md") lec-dir))
         (content  (if (file-exists-p template)
                       (with-temp-buffer
                         (insert-file-contents template)
                         (buffer-string))
                     (format "---\nclass: %s\ndate: %s\n---\n\n# Lecture\n\n" class date))))
    (with-temp-file target (insert content))
    (find-file target)))
```

---

### 5f. Weight chart in org-babel (alternative approach)

The user noted that org files can run Python inline and display plots. This is
an alternative to the elisp `create-image` approach above.

In a `dashboard.org` file (not the main elisp dashboard):

```org
* Weight

#+begin_src python :results file :file /tmp/weight-plot.png :exports results :eval yes
import subprocess, sys
result = subprocess.run(["/home/thijmen/.local/bin/plot-weights", "--cols", "80"],
                       capture_output=True, text=True)
print(result.stdout.strip())
#+end_src
```

When the block is evaluated (`C-c C-c`), org runs the script and displays the
resulting PNG inline in the org buffer.

**Tradeoffs vs. the elisp approach:**
- Pro: simpler code; org handles image display automatically
- Pro: the existing `plot-weights` script works unchanged
- Con: requires `C-c C-c` to refresh — doesn't render automatically on open
- Con: `#+PROPERTY: header-args :eval yes` can auto-eval on file open, but this
  is a security setting and Emacs will warn every time unless `org-confirm-babel-evaluate`
  is set to nil (not recommended globally)
- Con: lives in a separate org file, not integrated with the elisp `*Dashboard*` buffer

**Recommendation:** use the `create-image` approach (§5a) for the main dashboard
since it renders automatically. The org-babel approach is fine for a dedicated
`weights.org` file if you want to keep a persistent weight-review page.

---

## Checklist

### YouTube
- [ ] Verify yt-dlp is in packages; rebuild if not
- [ ] Open elfeed, run `M-x elfeed-update`, check entries appear
- [ ] Test `elfeed-tube-fetch` on a YouTube entry
- [ ] Add evil keybindings for elfeed-tube
- [ ] Decide: is text-only good enough, or keep yt-feed running alongside?

### Music
- [ ] Add `libmpdel` and `mpdel` to `home/emacs.nix`; rebuild
- [ ] Add mpdel use-package block to config.org
- [ ] Test `M-x mpdel-browser-open-artists`; verify keybindings
- [ ] Update `my/dash-music` to call mpdel
- [ ] Decide fate of EMMS block (remove or keep as fallback)

### Dashboards
- [ ] Add `my/dash--birthdays` to config.org; wire into `my/dashboard` right column
- [ ] Add `my/dash--insert-weight-chart` and `my/dash-log-weight` to config.org
- [ ] Add `w` key to `my/dashboard` local map and evil bindings
- [ ] Add `my/dash--recent-vault-folders` and `my/dash--knowledge-dirs` to config.org
- [ ] Add `my/vault-dashboard` function to config.org
- [ ] Update `my/dash-vault-work` to call `my/vault-dashboard` instead of dired
- [ ] Add `my/dash--fm-from-file` to config.org (shared helper for all dir scans)
- [ ] Add `my/dash--uni-deadlines`, `my/dash--uni-assignments`, `my/dash--uni-courses`,
      `my/dash--uni-planning` to config.org
- [ ] Check actual spelling of deadlines folder: `ls ~/Documents/BACKUP/Uni/Obsidian/Uni/Dead*`
- [ ] Add `my/uni-dashboard` function to config.org
- [ ] Update `my/dash-uni-work` to call `my/uni-dashboard` instead of dired
- [ ] Add `my/uni-course-view` function to config.org
- [ ] Add `my/uni-new-lecture` function to config.org
- [ ] Test each dashboard section with real data; check date parsing handles both YYYY-MM-DD and DD-MM-YYYY
- [ ] Update footer in `my/dashboard` to include `w` (weight)

### Email
- [ ] Add `mu` to system packages; rebuild
- [ ] Wire mu4e load-path in emacs.nix (check if standalone package exists first)
- [ ] Run `mu init` and `mu index` in terminal
- [ ] Add mu4e use-package block to config.org
- [ ] Test: open mu4e, check inbox, send a test reply
- [ ] Update `my/dash-email` to call `(mu4e)`
- [ ] Verify unread count in dashboard still works (it reads ~/Mail directly, should be fine)

### Messages
- [ ] Find wuzapi and wasabi GitHub repo coordinates
- [ ] Check if wasabi is on MELPA
- [ ] Follow wasabi.md step by step
