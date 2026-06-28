# Emacs gaps — complete setup plan

One rebuild, then config.org changes, then first-time terminal commands. No
second rebuild needed unless Wasabi/wuzapi packaging requires one (that part is
gated on research — see §5).

---

## Port inventory (do not conflict)

| Port | Service | Config |
|------|---------|--------|
| 6600 | MPD | `home/dotfiles/rmpc/config.ron` |
| 8080 | New tab page (python3 http.server) | `home/default.nix` |
| 8384 | Syncthing web UI | `modules/syncthing.nix` |
| 22000 | Syncthing file sync | `modules/syncthing.nix` |
| 21027 | Syncthing discovery | `modules/syncthing.nix` |
| 41641 | Tailscale | `modules/tailscale.nix` |

**wuzapi must NOT use 8080.** Use **8090** instead (set via flag or env var).

---

## Package management

Stay Nix throughout. All changes go to `home/emacs.nix` (Emacs packages) or
`modules/common.nix` (system tools). Follow the existing pattern exactly:

- **System tools** (`mu`, `yt-dlp`, `wuzapi`): go in `environment.systemPackages`
  in `modules/common.nix`, in the same alphabetical group as similar tools.
- **Emacs packages** (`mpdel`, `libmpdel`, `mu4e`, `wasabi`): go in
  `extraPackages = epkgs: with epkgs; [...]` in `home/emacs.nix`.

---

## Execution order

**Step 1 — Make all Nix changes** (all listed below under each section)
**Step 2 — Rebuild once**: `sudo nixos-rebuild switch --flake /etc/nixos#desktop`
**Step 3 — First-time terminal commands** (mu init, wuzapi QR scan — listed per section)
**Step 4 — Config.org changes** (no rebuild needed; restart Emacs to load)

---

## 1. YouTube — fix elfeed

### What's wrong

`M-x elfeed-update` runs but the list stays empty. This means elfeed-org is not
reading the org file — either `rmh-elfeed-org-files` points to a wrong path, or
`(elfeed-org)` never ran (use-package load order issue).

### Debug first (before touching anything)

Open Emacs and run these in order:

```
M-x elfeed                          ; open elfeed
C-h v rmh-elfeed-org-files RET     ; check what path it has
```

Expected value: `("/home/thijmen/.config/emacs/elfeed.org")`

If it's nil or wrong, elfeed-org's use-package block either didn't load or ran
before `rmh-elfeed-org-files` was set.

Also check `*Messages*` for any `use-package` errors after startup.

### Fix A — load order (most likely cause)

The elfeed-org block needs `(elfeed-org)` to be called in `:config`, and it must
load after `elfeed`. In config.org, verify the block reads exactly:

```elisp
(use-package elfeed-org
  :after elfeed
  :config
  (setq rmh-elfeed-org-files
        (list (expand-file-name "elfeed.org" user-emacs-directory)))
  (elfeed-org))
```

The `(elfeed-org)` call is what registers the hooks. Without it, nothing is read.

### Fix B — add yt-dlp to system packages

elfeed-tube uses yt-dlp for video metadata fetch. Add to `modules/common.nix`
in the same group as `yt-dlp` (check if already present — it may be there for mpv):

```nix
yt-dlp   # YouTube downloader; used by mpv and elfeed-tube
```

### Fix C — elfeed-tube keybindings

Once entries appear, add to the elfeed-tube use-package `:config` block:

```elisp
(evil-define-key 'normal elfeed-show-mode-map
  "F"   #'elfeed-tube-fetch       ; fetch description + metadata inline
  "C-m" #'elfeed-tube-mpv-play)   ; open video in mpv (C-m = Enter)
(evil-define-key 'normal elfeed-search-mode-map
  "F"   #'elfeed-tube-fetch)
```

### What to expect

Text list of entries, no thumbnails. `s` to filter (`+youtube`, `+physics`,
`+unread`). `F` fetches description inline. Enter plays in mpv. yt-feed remains
a better visual experience; keep it running alongside if the text view isn't
enough for daily use.

---

## 2. Music — mpdel

### Honest comparison with MusicBee

mpdel is a hierarchical MPD browser: Artists → Albums → Tracks. You navigate
with hjkl, add to queue, play. It is the closest Emacs equivalent to MusicBee's
three-pane library view — same concept, text-only. No album art, no waveform,
no drag-and-drop. If the keyboard-driven hierarchy is what you liked about
MusicBee, mpdel will feel familiar. If it was the visual design, nothing in
Emacs will replicate that.

EMMS is worse: it's a flat list and its browser is disorienting. mpdel is the
right call.

### Nix change — home/emacs.nix

Add to `extraPackages`:

```nix
# ── Music ─────────────────────────────────────────────────────────────────────
libmpdel    # MPD protocol library
mpdel       # Emacs MPD client (browser + queue)
```

Remove or keep `emms` — it can coexist but won't be the primary interface.

### Config.org — replace the EMMS section

Replace the existing `* Music Player (EMMS)` section with `* Music (mpdel)`:

```elisp
(use-package libmpdel
  :config
  (setq libmpdel-hostname "localhost"
        libmpdel-port 6600))   ; matches home/mpd.nix + rmpc config

(use-package mpdel
  :after libmpdel
  :config
  (mpdel-mode)

  (evil-define-key 'normal mpdel-browser-mode-map
    "j"   #'mpdel-browser-next-line
    "k"   #'mpdel-browser-previous-line
    "l"   #'mpdel-browser-open-entry
    "h"   #'mpdel-browser-back
    "g"   (lambda () (interactive) (goto-char (point-min)))
    "G"   (lambda () (interactive) (goto-char (point-max)))
    "a"   #'mpdel-browser-add
    "q"   #'bury-buffer
    "SPC" #'mpdel-core-toggle-play-pause)

  (evil-define-key 'normal mpdel-playlist-mode-map
    "j"   #'mpdel-playlist-next-line
    "k"   #'mpdel-playlist-previous-line
    "d"   #'mpdel-playlist-remove-from-queue
    "SPC" #'mpdel-core-toggle-play-pause
    "q"   #'bury-buffer))

;; Verify these function names with C-h f mpdel- after loading
(spc! "m m" '(mpdel-browser-open-artists  :wk "music browser")
      "m SPC" '(mpdel-core-toggle-play-pause :wk "play / pause")
      "m n"   '(mpdel-core-next            :wk "next")
      "m p"   '(mpdel-core-previous        :wk "prev")
      "m q"   '(mpdel-browser-open-current-playlist :wk "queue"))
```

### Dashboard update

In the Dashboard section, update `my/dash-music`:

```elisp
(defun my/dash-music ()
  (interactive)
  (mpdel-browser-open-artists))
```

---

## 3. Email — mu4e

### Which accounts will work

mu4e reads maildirs that mbsync syncs. mbsync is already running:

| Account | IMAP server | Status |
|---------|------------|--------|
| tidemanus@gmail.com | imap.gmail.com | ✅ already syncing to ~/Mail/Gmail/ |
| thijmen.nouwens@gmail.com | imap.gmail.com | ✅ declared in email.nix; confirm syncing |
| nouwens-lindemans.nl | vserver04.een2drie.nl | ✅ declared in email.nix; works once syncing |
| TU Delft | Office 365 | ❌ Exchange OAuth2 — skip for now, use browser |

### Nix changes

**`modules/common.nix`** — add `mu` in `environment.systemPackages`, near the
other mail tools (mbsync, msmtp, neomutt):

```nix
mu              # maildir indexer; includes mu4e elisp
```

**`home/emacs.nix`** — mu4e ships inside the `mu` system package, not as a
standalone nixpkgs emacs package. Add it via a load-path hook in `extraConfig`:

```nix
# in programs.emacs block, after extraPackages:
extraConfig = ''
  (add-to-list 'load-path
    "${pkgs.mu}/share/emacs/site-lisp/mu4e")
'';
```

Alternatively, check first: `nix-env -qaP 2>/dev/null | grep mu4e` — if a
standalone `mu4e` package exists in nixpkgs, just add it to `extraPackages`
like any other package and skip the `extraConfig` approach.

### First-time terminal commands (after rebuild)

```bash
mu init --maildir=~/Mail \
        --my-address=tidemanus@gmail.com \
        --my-address=thijmen.nouwens@gmail.com
mu index
```

Run `mu index` once; after that mu updates automatically when mbsync syncs
(mbsync is on a 5-minute timer already).

### Config.org — add `* Email (mu4e)` section

```elisp
(use-package mu4e
  :ensure nil   ; loaded from mu system package load-path, not ELPA

  :init
  (setq mu4e-maildir              (expand-file-name "~/Mail")
        mu4e-get-mail-command     "mbsync -a"
        mu4e-update-interval      300
        mu4e-sent-messages-behavior 'delete   ; Gmail saves server-side
        mu4e-user-mail-address-list
          '("tidemanus@gmail.com" "thijmen.nouwens@gmail.com")
        mu4e-compose-reply-to-address "tidemanus@gmail.com"
        ;; Dutch folder names (from email.nix)
        mu4e-drafts-folder "/Gmail/[Gmail]/Concepten"
        mu4e-sent-folder   "/Gmail/[Gmail]/Verzonden berichten"
        mu4e-trash-folder  "/Gmail/[Gmail]/Prullenbak"
        mu4e-refile-folder "/Gmail/[Gmail]/Alle e-mail")

  :config
  ;; Send via msmtp (already configured in email.nix)
  (setq message-send-mail-function       #'message-send-mail-with-sendmail
        sendmail-program                 (executable-find "msmtp")
        message-sendmail-extra-arguments '("--read-envelope-from")
        message-sendmail-f-is-evil       t)

  (setq mu4e-bookmarks
        '((:name "Inbox"   :query "maildir:/Gmail/INBOX"            :key ?i)
          (:name "Unread"  :query "flag:unread AND NOT flag:trashed" :key ?u)
          (:name "Today"   :query "date:today..now"                  :key ?t)))

  (setq mu4e-view-prefer-html    nil
        mu4e-html2text-command   "w3m -T text/html")

  (evil-define-key 'normal mu4e-headers-mode-map
    "j"   #'mu4e-headers-next
    "k"   #'mu4e-headers-prev
    "l"   #'mu4e-headers-view-message
    "h"   #'mu4e-headers-prev-unread   ; or bury — check what feels right
    "d"   #'mu4e-headers-mark-for-delete
    "u"   #'mu4e-headers-mark-for-unmark
    "r"   #'mu4e-compose-reply
    "R"   #'mu4e-compose-wide-reply
    "m"   #'mu4e-compose-new
    "gg"  (lambda () (interactive) (mu4e-headers-first))
    "G"   #'mu4e-headers-last
    "q"   #'mu4e-quit
    "?"   #'mu4e-display-manual)

  (evil-define-key 'normal mu4e-view-mode-map
    "j"   #'mu4e-view-headers-next
    "k"   #'mu4e-view-headers-prev
    "h"   #'mu4e-view-quit-message
    "r"   #'mu4e-compose-reply
    "R"   #'mu4e-compose-wide-reply
    "q"   #'mu4e-view-quit-message))

(spc! "e" '(mu4e :wk "email"))
```

### Dashboard update

```elisp
(defun my/dash-email ()
  (interactive)
  (mu4e))
```

---

## 4. Messages — Wasabi + wuzapi

### Architecture

```
WhatsApp ↔ wuzapi (Go daemon, port 8090) ↔ Wasabi (Emacs package)
```

wuzapi is a JSON-RPC HTTP bridge to WhatsApp via the whatsmeow library — same
underlying library as nchat. Wasabi is a native Emacs UI on top of it.

### Step 0 — Research required before any Nix work

Neither wuzapi nor Wasabi is in nixpkgs yet. Before writing derivations:

1. Find the wuzapi GitHub repo (search "wuzapi whatsmeow github"). Note the
   exact `owner/repo`, latest commit or tag, and whether it has a `go.sum`
   (needed for `vendorHash`).

2. Find the Wasabi GitHub repo (search "wasabi emacs whatsapp github"). Check
   if it's also on MELPA (`melpa.org/#/wasabi`) — if yes, it may already be in
   nixpkgs as `epkgs.wasabi` which would skip the `trivialBuild`.

3. Check nixpkgs: `nix-env -qaP 2>/dev/null | grep -i "wasabi\|wuzapi"`

Document coords here before proceeding:
```
wuzapi: github.com/OWNER/wuzapi  rev: COMMIT  hash: sha256-...  vendorHash: sha256-...
wasabi: github.com/OWNER/wasabi  rev: COMMIT  hash: sha256-...  (or: epkgs.wasabi)
```

### Step 1 — Package wuzapi (modules/common.nix or a new home/wuzapi.nix)

Create `home/wuzapi.nix` and import it in `home/default.nix`:

```nix
{ pkgs, config, ... }:
let
  wuzapi = pkgs.buildGoModule {
    pname   = "wuzapi";
    version = "0.x.x";           # fill from Step 0
    src = pkgs.fetchFromGitHub {
      owner = "OWNER";           # fill from Step 0
      repo  = "wuzapi";
      rev   = "COMMIT";
      hash  = "sha256-...";
    };
    vendorHash = "sha256-...";   # run build once to get this from the error
  };
in {
  home.packages = [ wuzapi ];

  # Stable data directory for WhatsApp session
  home.file.".local/share/wuzapi/.keep".text = "";

  systemd.user.services.wuzapi = {
    Unit = {
      Description = "wuzapi WhatsApp JSON-RPC bridge";
      After       = [ "network-online.target" ];
    };
    Service = {
      ExecStart       = "${wuzapi}/bin/wuzapi --port 8090";
      WorkingDirectory = "%h/.local/share/wuzapi";
      Restart         = "on-failure";
      RestartSec      = "10s";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
```

Port **8090** — avoids conflict with 8080 (new tab page).

### Step 2 — Package Wasabi (home/emacs.nix)

**If `epkgs.wasabi` exists in nixpkgs**: just add `wasabi` to `extraPackages`.

**If not in nixpkgs**, use `trivialBuild`:

```nix
(epkgs.trivialBuild {
  pname   = "wasabi";
  version = "0.x.x";
  src = pkgs.fetchFromGitHub {
    owner = "OWNER";    # fill from Step 0
    repo  = "wasabi";
    rev   = "COMMIT";
    hash  = "sha256-...";
  };
  # Check wasabi's Package-Requires header in wasabi.el for dependencies:
  packageRequires = with epkgs; [ websocket ];   # adjust as needed
})
```

### Step 3 — First-time setup (after rebuild + wuzapi starts)

```bash
# Start the service
systemctl --user start wuzapi

# Trigger QR code pairing — check wuzapi README for exact command.
# Usually something like:
curl -s http://localhost:8090/api/login | jq '.qrcode' | qrencode -t ANSI
# or wuzapi exposes a web UI at http://localhost:8090 — check docs
```

Scan the QR code with WhatsApp on your phone (Settings → Linked Devices).
Session is stored in `~/.local/share/wuzapi/` and persists across reboots.

### Step 4 — Config.org — add `* Messages (Wasabi)` section

```elisp
(use-package wasabi
  :ensure nil   ; loaded from Nix

  :init
  (setq wasabi-wuzapi-url "http://localhost:8090")

  :config
  ;; Check evil-collection first: M-x evil-collection-init after loading
  ;; If evil-collection has a wasabi entry, these may not be needed.
  ;; If not, define manually based on wasabi's actual mode maps.
  ;; Discover mode map names with: C-h v wasabi- TAB
  (with-eval-after-load 'wasabi
    (evil-define-key 'normal wasabi-mode-map   ; verify map name
      "j"   #'wasabi-next-chat
      "k"   #'wasabi-prev-chat
      "l"   #'wasabi-open-chat
      "h"   #'wasabi-back
      "g"   (lambda () (interactive) (goto-char (point-min)))
      "G"   (lambda () (interactive) (goto-char (point-max)))
      "q"   #'bury-buffer
      "?"   #'describe-mode))

  ;; Theme: check what faces wasabi defines after loading:
  ;; M-x customize-group RET wasabi RET
  ;; Override any hardcoded colours here:
  ;; (set-face-attribute 'wasabi-MESSAGE-FACE nil :foreground "#c4a882")
  )

(spc! "W" '(wasabi :wk "whatsapp"))   ; capital W — lowercase w is log-weight
```

All function names are placeholders — verify with `C-h f wasabi-` after loading.

### Dashboard update

```elisp
(defun my/dash-messages ()
  (interactive)
  (wasabi))   ; verify entry-point command name from wasabi README
```

---

## 5. Dashboards

### What perspective does

`perspective.el` creates named workspaces inside Emacs. Each perspective has its
own buffer list — buffers opened in "personal" don't appear in "uni" and vice
versa. Switching perspectives feels like switching KDE virtual desktops, but for
Emacs buffers.

Currently configured in config.org:
- `TAB p` → `perspective-personal` → switches to "personal" workspace
- `TAB u` → `perspective-uni` → switches to "uni" workspace
- `TAB TAB` → `persp-switch` (pick any workspace by name)
- Initial perspective on startup: "personal"

Currently `perspective-personal` calls `(find-file "~/org/personal/dashboard.org")`
and `perspective-uni` calls `(find-file "~/org/uni/dashboard.org")` — neither file
exists. These need to be replaced with dashboard function calls.

**Bidirectional wiring**: every dashboard function also switches to its perspective,
so calling `my/vault-dashboard` from anywhere always lands you in "personal", and
`my/uni-dashboard` always lands you in "uni". This means the perspective you're in
is always meaningful.

---

### 5a. Perspective wiring (update config.org)

Replace the `perspective-personal` and `perspective-uni` function bodies. In the
`* Workspaces (perspective)` section:

```elisp
(defun perspective-personal ()
  "Switch to personal perspective and open vault dashboard."
  (interactive)
  (persp-switch "personal")
  (my/vault-dashboard))

(defun perspective-uni ()
  "Switch to uni perspective and open uni dashboard."
  (interactive)
  (persp-switch "uni")
  (my/uni-dashboard))
```

And wrap the vault/uni dashboard functions to also switch perspective when called
directly (the bidirectional part):

```elisp
(defun my/vault-dashboard ()
  "Open vault dashboard in the personal perspective."
  (interactive)
  (persp-switch "personal")
  ;; ... rest of function body ...
  )

(defun my/uni-dashboard ()
  "Open uni dashboard in the uni perspective."
  (interactive)
  (persp-switch "uni")
  ;; ... rest of function body ...
  )
```

---

### 5b. Greeting dashboard — additions to my/dashboard

#### Birthdays

Add `my/dash--birthdays` as a shared helper (used by both greeting and vault
dashboard). Reads every `.md` in `VAULT/People/`, parses `birthday: YYYY-MM-DD`
or `birthday: DD-MM-YYYY` from YAML frontmatter, returns this month's entries.

```elisp
(defun my/dash--birthdays ()
  "List of formatted strings for people with birthdays this month."
  (let* ((people-dir (expand-file-name "People" my/dash-vault))
         (now        (decode-time))
         (cur-month  (nth 4 now))
         (cur-year   (nth 5 now))
         (months     '("Jan" "Feb" "Mar" "Apr" "May" "Jun"
                        "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
         results)
    (when (file-directory-p people-dir)
      (dolist (file (directory-files people-dir t "\\.md$"))
        (with-temp-buffer
          (insert-file-contents file nil 0 2000)
          (goto-char (point-min))
          (when (looking-at "---")
            (let ((end (save-excursion
                          (forward-line)
                          (re-search-forward "^---$" nil t))))
              (when end
                (let* ((fm   (buffer-substring-no-properties (point-min) end))
                       (bday (and (string-match
                                   "^birthday:[[:space:]]*\\([^\n]+\\)" fm)
                                  (string-trim (match-string 1 fm))))
                       (name (and (string-match
                                   "^name:[[:space:]]*\\([^\n]+\\)" fm)
                                  (string-trim (match-string 1 fm)))))
                  (when (and bday (not (string-empty-p bday)))
                    (let* ((parts (split-string bday "-"))
                           ;; Detect YYYY-MM-DD vs DD-MM-YYYY
                           (year  (if (= (length (nth 0 parts)) 4)
                                      (string-to-number (nth 0 parts))
                                    (string-to-number (nth 2 parts))))
                           (month (string-to-number (nth 1 parts)))
                           (day   (if (= (length (nth 0 parts)) 4)
                                      (string-to-number (nth 2 parts))
                                    (string-to-number (nth 0 parts)))))
                      (when (= month cur-month)
                        (let* ((age      (- cur-year year))
                               (bday-ts  (float-time
                                          (encode-time 0 0 12 day month cur-year)))
                               (diff     (/ (- bday-ts (float-time)) 86400))
                               (when-str (cond ((and (>= diff 0) (< diff 1)) "today!")
                                               ((> diff 0) (format "in %d days" (ceiling diff)))
                                               (t (format "%d days ago" (floor (abs diff)))))))
                          (push (format "%-28s  %s %2d   (%s, turning %d)"
                                        (or name (file-name-base file))
                                        (nth (1- month) months)
                                        day when-str age)
                                results))))))))))
    (sort results #'string<)))
```

Insert in the right column of `my/dashboard`, **before Deadlines**:

```elisp
(let ((bdays (my/dash--birthdays)))
  (when bdays
    (push "" right)
    (push (propertize "Birthdays" 'face 'font-lock-keyword-face) right)
    (dolist (b bdays) (push (concat "  " b) right))))
```

#### Weight chart (async PNG)

```elisp
(defun my/dash--insert-weight-chart ()
  "Run plot-weights async and insert the PNG at the end of the current buffer."
  (let ((buf (current-buffer)))
    (make-process
     :name     "plot-weights"
     :command  (list (expand-file-name "~/.local/bin/plot-weights")
                     "--cols" (number-to-string (- (window-width) 6)))
     :filter   #'ignore
     :sentinel (lambda (_proc _event)
                 (when (file-exists-p "/tmp/weight-plot.png")
                   (with-current-buffer buf
                     (when (buffer-live-p buf)
                       (let ((inhibit-read-only t))
                         (save-excursion
                           (goto-char (point-max))
                           (insert "\n")
                           (insert-image
                            (create-image "/tmp/weight-plot.png" 'png nil
                                          :max-width (- (window-width) 6)))
                           (insert "\n"))))))))))
```

#### Weight logging

```elisp
(defun my/dash-log-weight (weight)
  "Append WEIGHT (kg) as a new row to the weights markdown table."
  (interactive "nWeight (kg): ")
  (let* ((file  (expand-file-name
                  "Knowledge/Body & Movement/Bodybuilding/Stats/Weights list.md"
                  my/dash-vault))
         (today (format-time-string "%Y-%m-%d"))
         entries)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (while (re-search-forward
              "| *\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\) *| *\\([0-9.]+\\)" nil t)
        (push (cons (float-time (date-to-time (match-string 1)))
                    (string-to-number (match-string 2)))
              entries)))
    (let* ((now     (float-time))
           (ma (lambda (days)
                 (let* ((cut  (- now (* days 86400)))
                        (rel  (seq-filter (lambda (e) (>= (car e) cut)) entries))
                        (all  (mapcar #'cdr (append rel (list (cons now weight)))))
                        (n    (length all)))
                   (/ (apply #'+ all) n)))))
      (with-current-buffer (find-file-noselect file)
        (goto-char (point-max))
        (unless (bolp) (insert "\n"))
        (insert (format "| %s | %.1f | %.2f | %.2f | %.2f |\n"
                        today weight
                        (funcall ma 7)
                        (funcall ma 21)
                        (funcall ma 30)))
        (save-buffer)))
    (message "Logged %.1f kg  (%s)" weight today)
    (my/dash--insert-weight-chart)))
```

Add to `my/dashboard` local map and evil bindings:

```elisp
(local-set-key (kbd "w") #'my/dash-log-weight)
;; in the evil-define-key* loop:
("w" . my/dash-log-weight)
```

Add `"w"` to the footer `(dolist (item '(...)))` list.

Call `(my/dash--insert-weight-chart)` at the end of `my/dashboard`, after
`(switch-to-buffer buf)`.

---

### 5c. Vault dashboard — markdown (`my/vault-dashboard`)

Reads the markdown vault directly. Replaces the current dired call in
`my/dash-vault-work`. Always opens in the "personal" perspective.

**Add these shared helpers** (used by vault dashboard, and also by the greeting):

```elisp
(defun my/dash--recent-vault-folders (n)
  "Return N plists (:folder :name :path :age) for most recently modified vault folders."
  (let* ((out      (shell-command-to-string
                    (format "find %s -name '*.md' \
-not -path '*/.obsidian/*' -not -path '*/Templates/*' \
-not -path '*/Attachments/*' \
-printf '%%T@ %%p\\n' 2>/dev/null | sort -rn | head -80"
                            (shell-quote-argument my/dash-vault))))
         (by-folder   (make-hash-table :test 'equal))
         (folder-mtime (make-hash-table :test 'equal)))
    (dolist (line (split-string out "\n" t))
      (when (string-match "^\\([0-9.]+\\) \\(.+\\)$" line)
        (let* ((mt   (string-to-number (match-string 1 line)))
               (path (match-string 2 line))
               (rel  (file-relative-name path my/dash-vault))
               (folder (car (split-string rel "/"))))
          (when (and folder
                     (not (string-prefix-p "." folder))
                     (or (not (gethash folder folder-mtime))
                         (> mt (gethash folder folder-mtime))))
            (puthash folder mt folder-mtime)
            (puthash folder (cons path mt) by-folder)))))
    (seq-take
     (mapcar (lambda (f)
               (let* ((e    (gethash f by-folder))
                      (diff (/ (- (float-time) (cdr e)) 86400))
                      (age  (cond ((< diff 1) "today")
                                  ((< diff 2) "yesterday")
                                  ((< diff 7) (format "%d days ago" (floor diff)))
                                  ((< diff 14) "1 week ago")
                                  (t (format "%d weeks ago" (floor (/ diff 7)))))))
                 (list :folder f :path (car e)
                       :name (file-name-base (car e)) :age age)))
             (sort (hash-table-keys folder-mtime)
                   (lambda (a b) (> (gethash a folder-mtime)
                                    (gethash b folder-mtime)))))
     n)))

(defun my/dash--knowledge-dirs ()
  "Return list of (name . count) for each Knowledge/ subdirectory."
  (let ((kdir (expand-file-name "Knowledge" my/dash-vault)))
    (when (file-directory-p kdir)
      (mapcar (lambda (d)
                (cons (file-name-nondirectory d)
                      (string-to-number
                       (string-trim
                        (shell-command-to-string
                         (format "find %s -name '*.md' 2>/dev/null | wc -l"
                                 (shell-quote-argument d)))))))
              (seq-filter #'file-directory-p
                          (directory-files kdir t "^[^.]"))))))
```

**The vault dashboard function** (add as `** Vault dashboard` in `* Dashboard`):

```elisp
(defun my/vault-dashboard ()
  "Open personal vault dashboard in the personal perspective."
  (interactive)
  (persp-switch "personal")
  (let* ((buf      (get-buffer-create "*Vault*"))
         (todo-f   (expand-file-name "Misc/ToDo.md" my/dash-vault))
         (bdays    (my/dash--birthdays))
         (recent   (my/dash--recent-vault-folders 3))
         (projects (my/dash--parse-section todo-f "Projects"))
         (proj-idx (when projects
                     (% (1- (string-to-number (format-time-string "%j")))
                        (length projects))))
         (daily-dir (expand-file-name "Dailies" my/dash-vault))
         (dailies  (seq-take
                    (sort (directory-files daily-dir t "\\.md$")
                          (lambda (a b)
                            (> (float-time (file-attribute-modification-time
                                            (file-attributes a)))
                               (float-time (file-attribute-modification-time
                                            (file-attributes b))))))
                    5))
         (know     (my/dash--knowledge-dirs)))

    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq-local cursor-type nil)
        (insert "\n")
        (insert (propertize
                 (concat "VAULT  ·  " (format-time-string "%A %-d %B %Y"))
                 'face 'font-lock-keyword-face) "\n\n")

        (cl-flet ((section (header) (insert (propertize (concat "  " header "\n")
                                                         'face 'font-lock-keyword-face)))
                  (empty   ()       (insert (propertize "    — none —\n" 'face 'shadow)))
                  (link    (text path)
                            (insert "    ")
                            (insert-text-button text
                              'action (lambda (_) (find-file path))
                              'face 'default 'mouse-face 'highlight 'follow-link t)
                            (insert "\n")))

          ;; BIRTHDAYS
          (section "BIRTHDAYS THIS MONTH")
          (if bdays (dolist (b bdays) (insert "    " b "\n")) (empty))
          (insert "\n")

          ;; CONTINUE
          (section "CONTINUE")
          (if recent
              (dolist (r recent)
                (link (format "%-18s  %-32s  %s"
                              (plist-get r :folder)
                              (plist-get r :name)
                              (plist-get r :age))
                      (plist-get r :path)))
            (empty))
          (insert "\n")

          ;; PROJECTS
          (when projects
            (section "PROJECTS")
            (let ((i 0))
              (dolist (p projects)
                (insert (format "    %d  %s%s\n" (1+ i) p
                                (if (= i proj-idx)
                                    (propertize "  ← today"
                                                'face 'font-lock-keyword-face)
                                  "")))
                (setq i (1+ i))))
            (insert "\n"))

          ;; RECENT DAILY NOTES
          (section "RECENT DAILY NOTES")
          (if dailies
              (dolist (f dailies)
                (link (file-name-base f) f))
            (empty))
          (insert "\n")

          ;; KNOWLEDGE
          (section "KNOWLEDGE")
          (when know
            (let ((row "") (max-w 68))
              (dolist (kd know)
                (let ((entry (format "%s (%d)" (car kd) (cdr kd))))
                  (if (> (+ (length row) (length entry) 3) max-w)
                      (progn (insert "    " row "\n") (setq row entry))
                    (setq row (if (string-empty-p row) entry
                                (concat row "  " entry))))))
              (unless (string-empty-p row) (insert "    " row "\n"))))
          (insert "\n")))

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

    (switch-to-buffer buf)
    (my/dash--insert-weight-chart))
  buf)
```

**Update `my/dash-vault-work`**:

```elisp
(defun my/dash-vault-work ()
  (interactive)
  (my/vault-dashboard))
```

---

### 5d. Vault dashboard — org (`my/vault-dashboard-org`)

Same structure and keybindings as the markdown version. Reads `~/org/` instead
of the markdown vault. Uses `org-ql` for queries and org properties for metadata.

This function is the future replacement for `my/vault-dashboard`. When you
migrate to org, change `perspective-personal` to call this instead.

**Data sources:**

| Section | org equivalent |
|---------|---------------|
| BIRTHDAYS | org files in `~/org/personal/people/` with `:BIRTHDAY:` property |
| CONTINUE | same `find` + mtime approach, just on `~/org/personal/` |
| PROJECTS | `* Projects` heading in `~/org/personal/todo.org` |
| RECENT DAILY NOTES | `~/org/daily/YYYY-MM-DD.org` sorted by mtime |
| KNOWLEDGE | `~/org/personal/` subdirs with note count |
| WEIGHT CHART | same `my/dash--insert-weight-chart` call |

```elisp
(defvar my/dash-vault-org (expand-file-name "~/org/personal/")
  "Root directory of the org personal vault.")

(defun my/dash--birthdays-org ()
  "Birthdays from org People files (:BIRTHDAY: property)."
  (let* ((people-dir (expand-file-name "people" my/dash-vault-org))
         (now (decode-time))
         (cur-month (nth 4 now)) (cur-year (nth 5 now))
         (months '("Jan" "Feb" "Mar" "Apr" "May" "Jun"
                   "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"))
         results)
    (when (file-directory-p people-dir)
      (dolist (file (directory-files people-dir t "\\.org$"))
        (with-temp-buffer
          (insert-file-contents file nil 0 3000)
          (org-mode)
          (let ((bday (org-entry-get (point-min) "BIRTHDAY" t))
                (name (org-entry-get (point-min) "ITEM" t)))
            (when bday
              ;; same date parsing / birthday logic as my/dash--birthdays
              ;; (copy the inner let* from §5b, swap variable names as needed)
              )))))
    results))

(defun my/vault-dashboard-org ()
  "Open personal vault dashboard (org version) in the personal perspective."
  (interactive)
  (persp-switch "personal")
  ;; Same render logic as my/vault-dashboard but:
  ;; - Replace (my/dash--birthdays) with (my/dash--birthdays-org)
  ;; - Replace (my/dash--recent-vault-folders 3) with org version
  ;; - Replace (my/dash--parse-section todo-f "Projects")
  ;;   with (org-ql-query :from "~/org/personal/todo.org" :where '(heading "Projects"))
  ;; - Replace Dailies dir with "~/org/daily/"
  ;; - Replace (my/dash--knowledge-dirs) with org subdir version
  ;;
  ;; Stub: implement incrementally as ~/org/ content grows
  (message "org vault dashboard: implement as org migration proceeds"))
```

Wire into perspective when ready:

```elisp
;; In perspective-personal, swap when migrating:
;; (my/vault-dashboard)      ← current (markdown)
;; (my/vault-dashboard-org)  ← future (org)
```

---

### 5e. Uni dashboard — markdown (`my/uni-dashboard`)

Check the actual deadlines folder name first:
```bash
ls ~/Documents/BACKUP/Uni/Obsidian/Uni/Dead*
```
The neovim source has `Deadines/` (one 'l') — confirm before writing paths.

**Shared helper — frontmatter from file** (needed for directory scanning):

```elisp
(defun my/dash--fm-from-file (file key)
  "Return frontmatter value of KEY from FILE, or nil."
  (with-temp-buffer
    (insert-file-contents file nil 0 2000)
    (goto-char (point-min))
    (when (looking-at "---")
      (let ((end (save-excursion
                   (forward-line)
                   (re-search-forward "^---$" nil t))))
        (when end
          (let ((fm (buffer-substring-no-properties (point-min) end)))
            (and (string-match (concat "^" (regexp-quote key)
                                       ":[[:space:]]*\\([^\n]*\\)") fm)
                 (string-trim (match-string 1 fm)))))))))
```

**Upcoming deadlines helper:**

```elisp
(defun my/dash--uni-deadlines ()
  "Upcoming deadlines from UNI/Deadines/ (sorted, incomplete only)."
  (let* ((dir (expand-file-name "Deadines" my/dash-uni))  ; verify spelling
         results)
    (when (file-directory-p dir)
      (dolist (file (directory-files dir t "\\.md$"))
        (let* ((completed (my/dash--fm-from-file file "completed"))
               (date-str  (my/dash--fm-from-file file "date"))
               (title     (my/dash--fm-from-file file "title"))
               (class     (my/dash--fm-from-file file "class"))
               (time-str  (my/dash--fm-from-file file "startTime")))
          (when (and date-str
                     (not (member completed '("true" "yes" "True" "Yes"))))
            (let* ((ts   (float-time
                          (date-to-time
                           (concat (my/dash--normalize-date date-str) " 12:00:00"))))
                   (diff (/ (- ts (float-time)) 86400)))
              (when (>= diff 0)
                (push (list :text (format "%-44s  %s%s   (%s)"
                                          (if (and class title)
                                              (concat class " — " title)
                                            (or title (file-name-base file)))
                                          date-str
                                          (if (and time-str (not (string-empty-p time-str)))
                                              (concat "  " time-str) "")
                                          (if (< diff 1) "TODAY"
                                            (format "in %d days" (ceiling diff))))
                            :diff diff :path file)
                      results))))))
    (sort results (lambda (a b) (< (plist-get a :diff) (plist-get b :diff))))))
```

**Active assignments helper:**

```elisp
(defun my/dash--uni-assignments ()
  "Ungraded assignments from UNI/Assignments/ (sorted by deadline)."
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
                   (when-str (cond ((null diff) "?")
                                   ((< diff 1) "TODAY")
                                   ((>= diff 1) (format "in %d days" (ceiling diff)))
                                   (t (format "%dd ago" (floor (abs diff)))))))
              (push (list :text  (format "%-35s  %-14s  %s   (%s)"
                                         (file-name-base file)
                                         (or atype "") (or deadline "") when-str)
                          :diff  (or diff 9999) :path file)
                    results))))))
    (sort results (lambda (a b) (< (plist-get a :diff) (plist-get b :diff))))))
```

**Courses helper:**

```elisp
(defun my/dash--uni-courses ()
  "All courses from UNI/Classes/, sorted by Q."
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

**Planning table helper** (reads `## Planning` from Uni MOC.md, renders markdown
pipe table as unicode — org tables render automatically so this helper is only
needed for the markdown dashboard version):

```elisp
(defun my/dash--uni-planning ()
  "Read ## Planning from Uni MOC.md; render markdown table as unicode strings."
  (let ((moc (expand-file-name "Uni MOC.md" my/dash-uni))
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
    (while (and lines (string-blank-p (car lines))) (setq lines (cdr lines)))
    (while (and lines (string-blank-p (car (last lines)))) (setq lines (butlast lines)))
    (dolist (line lines)
      (cond
       ;; separator |---|---| → ├───┼───┤
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

**Full uni dashboard function** (add as `** Uni dashboard` in `* Dashboard`):

```elisp
(defun my/uni-dashboard ()
  "Open uni dashboard in the uni perspective."
  (interactive)
  (persp-switch "uni")
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
        (insert (propertize
                 (concat "UNI  ·  " (format-time-string "%A %-d %B %Y"))
                 'face 'font-lock-keyword-face) "\n\n")

        (cl-flet ((section (h) (insert (propertize (concat "  " h "\n")
                                                    'face 'font-lock-keyword-face)))
                  (empty   ()  (insert (propertize "    — none —\n" 'face 'shadow)))
                  (link    (text path)
                            (insert "    ")
                            (insert-text-button text
                              'action (lambda (_) (find-file path))
                              'face 'default 'mouse-face 'highlight 'follow-link t)
                            (insert "\n")))

          ;; UPCOMING DEADLINES
          (section "UPCOMING DEADLINES")
          (if deadlines
              (dolist (d deadlines) (link (plist-get d :text) (plist-get d :path)))
            (empty))
          (insert "\n")

          ;; ACTIVE ASSIGNMENTS
          (section "ACTIVE ASSIGNMENTS")
          (if assignments
              (dolist (a assignments) (link (plist-get a :text) (plist-get a :path)))
            (empty))
          (insert "\n")

          ;; COURSES (clickable → course view)
          (section "COURSES")
          (if courses
              (dolist (c courses)
                (let ((course c))
                  (insert "    ")
                  (insert-text-button
                   (format "%-40s  Q%-8s  %s"
                           (plist-get c :name)
                           (plist-get c :Q)
                           (plist-get c :code))
                   'action (lambda (_) (my/uni-course-view course))
                   'face 'default 'mouse-face 'highlight 'follow-link t)
                  (insert "\n")))
            (empty))
          (insert "\n")

          ;; PLANNING
          (section "PLANNING  (from Uni MOC)")
          (if planning
              (dolist (l planning) (insert "    " l "\n"))
            (empty))
          (insert "\n")))

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

---

### 5f. Uni dashboard — org (`my/uni-dashboard-org`)

Parallel org version. Uses org-ql and org properties instead of YAML frontmatter.

```elisp
(defvar my/dash-uni-org (expand-file-name "~/org/uni/")
  "Root of the org uni vault.")

(defun my/uni-dashboard-org ()
  "Open uni dashboard (org version) in the uni perspective."
  (interactive)
  (persp-switch "uni")
  ;; Same render structure as my/uni-dashboard but:
  ;; - Deadlines: (org-ql-select "~/org/uni/deadlines.org"
  ;;                '(and (todo) (deadline :from today :to +60)))
  ;; - Assignments: org-ql query on assignments file, filter by :GRADE: property
  ;; - Courses: org headings in "~/org/uni/courses.org"
  ;; - Planning: org table in "~/org/uni/moc.org" under * Planning heading
  ;;   (org tables render automatically — no unicode conversion needed)
  ;;
  ;; Stub: implement as ~/org/uni/ content is created
  (message "org uni dashboard: implement as org migration proceeds"))
```

Wire into perspective when ready:

```elisp
;; In perspective-uni, swap when migrating:
;; (my/uni-dashboard)      ← current (markdown)
;; (my/uni-dashboard-org)  ← future (org)
```

**Note on org tables**: In org-mode, `|` tables render automatically with proper
alignment — no unicode conversion helper is needed. The `my/dash--uni-planning`
helper (§5e) is only for the markdown dashboard that reads the markdown MOC file.

---

### 5g. Course view (`my/uni-course-view`)

Called when clicking a course in the uni dashboard. Shows lectures, assignments,
and summary file for that course.

```elisp
(defun my/uni-course-view (course)
  "Buffer listing lecture notes and assignments for COURSE plist."
  (let* ((shorthand (plist-get course :shorthand))
         (name      (plist-get course :name))
         (code      (plist-get course :code))
         (lec-dir   (expand-file-name "Lecture" my/dash-uni))
         lectures assignments summary-file)

    ;; Lectures matching this course
    (when (file-directory-p lec-dir)
      (dolist (file (directory-files lec-dir t "\\.md$"))
        (let* ((cls   (my/dash--fm-from-file file "class"))
               (fname (file-name-base file)))
          (when (or (string= cls shorthand)
                    (string= cls name)
                    (string= cls code)
                    (string-prefix-p (downcase shorthand) (downcase fname)))
            (let* ((ds   (or (my/dash--fm-from-file file "date")
                             (and (string-match "[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}" fname)
                                  (match-string 0 fname)) ""))
                   (title (or (my/dash--fm-from-file file "title") fname)))
              (push (list :name title :date ds :path file) lectures))))))
    (setq lectures (sort lectures
                          (lambda (a b) (string< (plist-get a :date)
                                                  (plist-get b :date)))))

    ;; Assignments for this course
    (dolist (a (my/dash--uni-assignments))
      (when (string= (my/dash--fm-from-file (plist-get a :path) "class") shorthand)
        (push a assignments)))

    ;; Summary file (UNI/Summary/<name> Summary.md)
    (dolist (candidate
             (list (expand-file-name (concat name " Summary.md")
                                     (expand-file-name "Summary" my/dash-uni))
                   (expand-file-name (concat shorthand " Summary.md")
                                     (expand-file-name "Summary" my/dash-uni))))
      (when (and (file-exists-p candidate) (null summary-file))
        (setq summary-file candidate)))

    ;; Render
    (let ((buf (get-buffer-create (format "*Course: %s*" name))))
      (with-current-buffer buf
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert "\n")
          (insert (propertize (format "%s  (%s)\n\n" name code)
                              'face 'font-lock-keyword-face))

          (cl-flet ((section (h) (insert (propertize (concat "  " h "\n")
                                                      'face 'font-lock-keyword-face)))
                    (empty   ()  (insert (propertize "    — none —\n" 'face 'shadow)))
                    (link    (text path)
                              (insert "    ")
                              (insert-text-button text
                                'action (lambda (_) (find-file path))
                                'face 'default 'mouse-face 'highlight 'follow-link t)
                              (insert "\n")))

            (section "SUMMARY")
            (if summary-file (link (file-name-base summary-file) summary-file) (empty))
            (insert "\n")

            (section "ASSIGNMENTS")
            (if assignments
                (dolist (a assignments) (link (plist-get a :text) (plist-get a :path)))
              (empty))
            (insert "\n")

            (section (format "LECTURES  (%d)" (length lectures)))
            (if lectures
                (let ((i 1))
                  (dolist (l lectures)
                    (link (format "%2d.  %-13s  %s" i
                                  (plist-get l :date) (plist-get l :name))
                          (plist-get l :path))
                    (setq i (1+ i))))
              (empty))))

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

### 5h. New lecture helper (`my/uni-new-lecture`)

```elisp
(defun my/uni-new-lecture ()
  "Create a lecture note from template and open it."
  (interactive)
  (let* ((class   (read-string "Class shorthand: "))
         (date    (format-time-string "%Y-%m-%d"))
         (lec-dir (expand-file-name "Lecture" my/dash-uni))
         (tmpl    (expand-file-name "Templates/Lecture.md" my/dash-uni))
         (target  (expand-file-name (concat class " " date ".md") lec-dir))
         (content (if (file-exists-p tmpl)
                      (with-temp-buffer (insert-file-contents tmpl) (buffer-string))
                    (format "---\nclass: %s\ndate: %s\n---\n\n# Lecture\n\n"
                            class date))))
    (with-temp-file target (insert content))
    (find-file target)))
```

---

## Single rebuild — complete Nix change list

All changes below happen in one editing session; one rebuild covers all of them.

### modules/common.nix

In `environment.systemPackages`, add near the other mail/media tools:

```nix
mu              # maildir indexer; mu4e ships inside it
yt-dlp          # YouTube/video downloader (check if already present)
```

### home/emacs.nix

In `extraPackages = epkgs: with epkgs; [...]`, add:

```nix
# ── Music ─────────────────────────────────────────────────────────────────────
libmpdel
mpdel

# ── Email ─────────────────────────────────────────────────────────────────────
# mu4e is loaded via load-path (see extraConfig below), not from epkgs
# unless nix-env -qaP | grep mu4e shows a standalone package
```

In the `programs.emacs` block, add `extraConfig` if mu4e isn't a standalone
nixpkgs package:

```nix
extraConfig = ''
  (add-to-list 'load-path
    "${pkgs.mu}/share/emacs/site-lisp/mu4e")
'';
```

### home/default.nix

Import the new wuzapi file (once repo coords are known):

```nix
imports = [
  # ... existing ...
  ./wuzapi.nix   # add when repo coords are confirmed
];
```

### home/wuzapi.nix (new file — create after Step 0 research)

Full file contents in §4 Step 1 above. Port 8090.

---

## Checklist

### Before rebuild
- [ ] Verify yt-dlp not already in modules/common.nix (search before adding)
- [ ] Confirm `nix-env -qaP 2>/dev/null | grep mu4e` result → choose epkgs or extraConfig
- [ ] Research wuzapi + wasabi repo coords (§4 Step 0) — if found, create home/wuzapi.nix

### Nix changes
- [ ] `modules/common.nix`: add `mu`, `yt-dlp`
- [ ] `home/emacs.nix`: add `libmpdel`, `mpdel`; add mu4e load-path via extraConfig (or epkgs)
- [ ] `home/wuzapi.nix`: create (if coords found)
- [ ] `home/default.nix`: import wuzapi.nix (if created)

### Rebuild
- [ ] `sudo nixos-rebuild switch --flake /etc/nixos#desktop`

### After rebuild — terminal commands
- [ ] `mu init --maildir=~/Mail --my-address=tidemanus@gmail.com --my-address=thijmen.nouwens@gmail.com`
- [ ] `mu index`
- [ ] `systemctl --user start wuzapi` (if wuzapi packaged)
- [ ] Scan wuzapi QR code for WhatsApp link (if wuzapi running)
- [ ] Verify `ls ~/Mail/Gmail/INBOX/` has messages

### Config.org changes (no rebuild — restart Emacs to load)
- [ ] elfeed-org block: ensure `(elfeed-org)` is called in `:config`; restart; test `M-x elfeed-update`
- [ ] Add `yt-dlp` fix note if elfeed-tube still fails after `:config` fix
- [ ] Replace EMMS section with mpdel section; update `my/dash-music`
- [ ] Add mu4e use-package block; update `my/dash-email`
- [ ] Update `perspective-personal` and `perspective-uni` to call dashboard functions
- [ ] Add `my/dash--birthdays` helper
- [ ] Add `my/dash--insert-weight-chart` and `my/dash-log-weight`
- [ ] Wire birthdays + weight chart + `w` key into `my/dashboard`
- [ ] Add `my/dash--recent-vault-folders` and `my/dash--knowledge-dirs`
- [ ] Add `my/vault-dashboard` function; update `my/dash-vault-work`
- [ ] Add `my/vault-dashboard-org` stub; update `perspective-personal`
- [ ] Confirm deadlines folder spelling: `ls ~/Documents/BACKUP/Uni/Obsidian/Uni/Dead*`
- [ ] Add `my/dash--fm-from-file` helper
- [ ] Add `my/dash--uni-deadlines`, `my/dash--uni-assignments`, `my/dash--uni-courses`, `my/dash--uni-planning`
- [ ] Add `my/uni-dashboard` function; update `my/dash-uni-work`
- [ ] Add `my/uni-dashboard-org` stub
- [ ] Add `my/uni-course-view` function
- [ ] Add `my/uni-new-lecture` function
- [ ] Add Wasabi use-package block (if packaged); update `my/dash-messages`

### After config.org changes
- [ ] Test `TAB p` → personal perspective + vault dashboard opens
- [ ] Test `TAB u` → uni perspective + uni dashboard opens
- [ ] Test weight chart renders in both greeting and vault dashboards
- [ ] Test `w` logs a weight and re-renders chart
- [ ] Test course view: click a course, see lectures
- [ ] Test `M-x mu4e` → inbox appears
- [ ] Test mpdel: `M-x mpdel-browser-open-artists` → artist list
- [ ] Sync config.org back to /etc/nixos/home/dotfiles/emacs/config.org
- [ ] Commit + update generations.md
