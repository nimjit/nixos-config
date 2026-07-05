# Emacs — Current State

*Last updated: 2026-07-04*


---

## New plans and notes from using emacs for a bit longer: [2026-07-04]

### Open problems

There are still a few open problems in the current state of the emacs configuration.
1. Client/Server relation
    The client server relation in emacs is working correctly, however it creates it's own problems sometimes.
    - Restarting is not as trivial as it would be without a client server relation.
    - Sometimes the config state is still the older version of the emacs configuration, after I updated config.org
2. Config.org not always loaded correctly
    - The font and typography I defined in config.org is not set correctly on startup.
3. Youtube feed is not quite where I want it.
    - The feed does not update, I think it could be the same issue as the config.org not retangling.
    - The feed itself does work, but I think I prefer the visual styling of my terminal setup. A single column with the thumbnail, details and the subscript. Instead of a list on the left and a single instance of the thumbnail and details on the right.
4. Performance
    - This is not a huge worry or big difference, but I do notice the difference moving from emacs into my terminal or neovim. It's just faster. I think a big part of this is the hold delay, which seems slower in emacs.
5. ESC to exist
    - This is not so much a problem as it is something I find confusing. When I accidentally type a leader key, any leader key, it waits for the next keypress. But I'm used to just pressing ESC then to escape, but it just registers this as any other key. There is also no timeout. So each time I accidentally press a space, control, meta, I have to press escape at least twice to escape the sequence.
6. Google calendar prompt
    Google calendar still prompts me personally very often to log in and it is very inconvenient. Emacs fully stops when the prompt opens and I have to hunt for it in an open browser.
7. The whatsapp emacs client is still not set up correctly.

### Improvement ideas

1. I have looked into the typst inline math problem and I have a few ideas.
    I understand now that there are no current larger projects that do what I want.
    Most people who write inline maths in org files just use latex, because they know it. 
    I know it too, but I prefer the typst syntax. It's speed is not so relevant for this, as it is for .typ files.
    But I do think it is possible to make a typst preview handler that works well, given that this exact thing exists in obsidian.
    - I essentially want to transpile the typst-mate plugin from obsidian into emacs for org-mode.
    If this is really not possible, I may need to consider moving to latex again, though I find the typing experience quite bad.
2. Org-mode and Org-agenda
    I was just setting up the tasks plugin for my girlfriend in obsidian, and realised that most, if not all, of its features exist in org-mode. 
    Then I realised how I might use it. 
    I don't really need org-mode for this, as I've created a system to do all of it for me, but I currently don't have a good tasks setup and org-mode would do this for me.
    - So I want to create a tasks system in org-mode which can for now sit on its own.
    - Maybe this will be a reason to fully switch to .org files. Then I would need to recheck and recompile my markdown into org-mode files.
    This is almost fully done, but I would want to update this.
3. I want to incorporate my graph views more into emacs. They are currently a bit out of date, and ugly too, so I want to improve them. But they can just be static as they are now, as I prefer this.
4. The terminal
    - The terminal experience in emacs is a bit slow, especially compared to kitty. Though I did learn there are some integrations between emacs and kitty, so I want to figure those out. Then I could continue to gain the GPU performance of kitty when I want terminal applications.
    - I also currently have claude code running in a terminal inside emacs (and neovim). In neovim this worked well, but in emacs, it feels a bit off for some reason. So I want to implement a claude-code window without needing the full terminal emulation layer below it. Like agent-shell
5. Youtube -> mpv inside emacs
    Currently the youtube feed opens mpv, which opens in a seperate instance. 
    - I would like this to open inside an emacs window on the side.
6. Auto detect changes in files
    This is something which I've gotten quite used to and feels really cool. Whenever you update something here, it gets seen and is immediately visible everywhere in your system.
    I want emacs to have this too.
7. org-cal
    I find the current mini-buffer look a little confusing, especially because it is still empty for now.
    - I think something more like a week column view, like other calendars would look good. Probably not to replace the mini-buffer, but to ammend it.
8. Line numbers
    - I think I want line numbers in org files too, what is the consensus on this? If there is one.

### Inspirations
- Vulpea
I read about this, and it seems to add a number of things that are native in obsidian into emacs. This seems to make sense to me as I now see obsidian as a more modern, but less powerful version of emacs.
- Obsidian.el
The links jumping and such would be quite nice for me, coming from obsidian. Though I wonder what exactly it adds if I don't use obsidian alongside emacs. May be insteresting to take further inspiration from this though. Just take a couple of functions from it.
- ERC/mastodon/etc.
I've read about this and I'm interested in whether I'd use anything like this. I don't really use social media at all, but maybe if it's convenient and actually adds anything, it could be fun to have access to it.
- I want to dive slightly deeper into distributions and how they do their visuals. I've seen some with sidebar file structures and sidebar tasks, they all have some kind of dashboard. I want to take inspiration from this.
    - nano emacs and others looked really nice and I think the aesthetics of emacs + moving around files and inside files are probably the two most important aspects for me.
- Some reddit posters who seem really knowlegable
    - Nicholas-Gougier
    - WassupMahFelloG
    - tarsius_

### Fun things I saw that could be a fun addition in my spare time
- Lichess.el

---

## History

A previous AI-generated config was built with evil, doom-style leader bindings,
org-roam, magit, and a full package set. It was opaque — I didn't understand what
any of it did. At 4K resolution (200% scaling) it was also slow because Cairo CPU
rasterization in emacs-pgtk can't GPU-accelerate at that scale. Both issues together
led to never using it.

That config is no longer in the repo. At 100% scaling the performance bottleneck
disappears (Cairo scales linearly with pixel count, not screen size). The new
approach: build incrementally, understand each piece before adding the next.

The key gotchas from the old config that still apply:
- `(setq evil-want-keybinding nil)` must be in `:init`, before evil-collection loads
- Unbind SPC from evil-motion-state AFTER `(evil-mode 1)` in `:config`
- Never byte-compile config.el — `general-create-definer` macros resolve at runtime
- `xdg.configFile."emacs/init.el".source = ...` bypasses Stylix; use standalone `ukiyo-theme.el`
- If adding org-roam later: `(setq org-roam-directory ...)` must come BEFORE the `use-package` form
- `org-typst-preview--render` had a missing `)` that nested all subsequent defuns inside it — fixed 2026-06-29. Always check config.el paren balance directly, not config.org src blocks.

---

## What is built and working

### Core

| Feature | Status | Notes |
|---------|--------|-------|
| Evil + evil-collection + evil-goggles | ✅ | SPC leader via general.el |
| Ukiyo theme | ✅ | From `~/.config/emacs/themes/ukiyo-theme.el` |
| Font | ✅ | CMU Typewriter Text 14 |
| Auto-revert (inotify) | ✅ | No polling; buffers sync with external changes instantly |
| Server/daemon | ✅ | Systemd user service; `emacsclient -c` connects in ~100ms |
| which-key | ✅ | 0.4s delay |
| Backup/lockfiles | ✅ | `make-backup-files nil`, `create-lockfiles nil` — no scattered files |
| Completion stack | ✅ | vertico + marginalia + orderless + consult + embark |
| Avy + projectile | ✅ | `C-;` for char jump |
| Jinx spell check | ✅ | en_UK + nl_NL via enchant2/hunspell |
| Dired | ✅ | Reasonable defaults set |
| recentf | ✅ | 200 items |

### Writing / Notes

| Feature | Status | Notes |
|---------|--------|-------|
| Org-mode | ✅ | Full config: todo keywords, agenda, babel, folding |
| Org-roam | ✅ | `~/org/` root; dailies in `~/org/daily/` |
| Org-roam-ui | ✅ | Graph view via `SPC n g` |
| Org-ql | ✅ | Loaded; used for deadline queries |
| Org-gcal | ✅ | 10 Google calendars syncing to `~/org/calendars/`; auto-syncs every 10min |
| Org capture templates | ✅ | Personal (concept, essay, book, paper, person ×2) + uni (class, lecture, assignment) + inbox |
| Org-modern | ✅ | Custom stars, modern tag/table rendering |
| Org-transclusion | ✅ | `SPC t t` toggle; used for lecture→summary workflow |
| Citar + org-roam-bibtex | ✅ | BibTeX at `~/org/library.bib`; fuzzy search |
| Typst math preview | ✅ | `$...$` renders as inline SVG overlay; `SPC t p` toggle mode |
| Markdown reading mode | ✅ | `SPC t r` in markdown: hides markup, read-only, `q` to exit |
| Magit + diff-hl | ✅ | `SPC g g` for status; gutter indicators in prog-mode |

### Media / External tools

| Feature | Status | Notes |
|---------|--------|-------|
| elfeed + elfeed-org + elfeed-tube | ✅ | Feeds in `~/.config/emacs/elfeed.org`; YouTube UULF URLs included; category tags on all headings |
| Music (mpdel) | ✅ | `SPC m m` two-panel view (dir browser left, cover art right); `SPC m s` slim side player; `SPC m SPC` play/pause; cover art from `~/Music/Artist/Album/cover.jpg` |
| Email (mu4e) | ✅ configured | Reads `~/Mail/`; msmtp send; 3 accounts; evil keybindings. **Needs `mu init` + `mu index` first time** |
| Calendar | ✅ | `SPC a` → org-agenda (org-gcal keeps it synced) |
| PDF tools | ✅ | `pdf-tools-install`; evil keybindings (hjkl, H/W fit, +/- zoom) |

### Dashboard system

All implemented in the `* Dashboard` section of config.org.

| Component | Status | Notes |
|-----------|--------|-------|
| `my/dashboard` (greeting) | ✅ | Date/weather/fortune header; today/tomorrow khal events; timetable 09–22; birthdays/deadlines/todo/mail/messages right column; footer with all shortcuts |
| Olivetti centering | ✅ | 180 char body width |
| Evil keybindings (greeting) | ✅ | Set after `switch-to-buffer` to avoid evil reinit clobber |
| Weight chart (async PNG) | ✅ | `my/dash--insert-weight-chart`; sentinel fixed with `condition-case`; inserts at point-max after async plot |
| Weight logging | ✅ | `my/dash-log-weight` (`w`); computes 7/21/30 day moving averages |
| Birthday reader | ✅ | Parses People/ YAML frontmatter; YYYY-MM-DD and DD-MM-YYYY |
| Mail count | ✅ | Scans `~/Mail/*/INBOX/new/`; shows sender names |
| Messages count | ✅ | Reads `/tmp/nchat-unread` |
| `my/vault-dashboard` | ✅ | Birthdays, recent folders, projects, daily notes, knowledge dir counts; org-mode rendering with clickable links |
| `my/uni-dashboard` | ✅ | Deadlines, assignments, courses, planning table; org-mode rendering |
| `my/uni-course-view` | ✅ | Summary, assignments, lectures per course |
| `my/news-view` | X | One headline per country from elfeed; 16 countries; org-mode, news update not working yet |
| `my/render-md-table` | X | Box-drawing table renderer; table is wider than window |
| `my/yt-view` | ✅ | Single-column YouTube viewer: inline thumbnails (GUI) / ░ placeholders (terminal); index-based j/k; hl-line highlight; o=browser, c=category, u=hook-refresh, q=quit; auto-fetches missing thumbs async |
| Planning table | ✅ | Reads `# Planning` from Uni MOC.md; renders as box-drawing via `my/render-md-table` |
| `my/uni-new-lecture` | ✅ | Creates from template or default YAML |
| Auto-open on client frame | ✅ | `server-after-make-frame-hook` opens dashboard in new client |

### Workspaces

| Perspective | Status | Notes |
|-------------|--------|-------|
| personal | ✅ | `TAB p` → switches to "personal" + opens `my/vault-dashboard` |
| uni | ✅ | `TAB u` → switches to "uni" + opens `my/uni-dashboard` |
| emacs-conf | ✅ | `TAB e` → vterm (claude) left + config.org right |
| nixos-conf | ✅ | `TAB n` → dired + vterm (claude) + magit |

### WhatsApp (wuzapi)

wuzapi runs as a user systemd service (`home/wuzapi.nix`). Emacs has the setup flow:

| Step | Status | Notes |
|------|--------|-------|
| wuzapi user service | ✅ | Port 8089; data at `~/.local/share/wuzapi/`; `.env` auto-loaded |
| `my/wuzapi-create-user` | X | `M-x my/wuzapi-create-user` — run once; saves token to `my/wuzapi-token`, gives 404 Error. |
| `my/wuzapi-connect` | ✅ | `M-x my/wuzapi-connect` — renders QR PNG via `find-file` |
| `my/dash-messages` | ✅ | `m` in dashboard: calls create-user if no token, else connect |
| WhatsApp linked | ❌ | QR scan not done yet. Run setup flow (see below). |

---

## First-time setup still needed

These are one-time commands, not config changes.

### 1. mu4e — `mu init` + `mu index`

```bash
mu init --maildir=~/Mail \
        --my-address=tidemanus@gmail.com \
        --my-address=thijmen.nouwens@gmail.com \
        --my-address=thijmen@nouwens-lindemans.nl
mu index
```

After that, `M-x mu4e` should open to inbox. mbsync already runs on a 5-minute timer so subsequent syncs are automatic.

### 2. wuzapi — QR scan

```
M-x my/wuzapi-create-user    ; creates user, saves token (run once)
M-x my/wuzapi-connect        ; fetches QR code PNG, opens it in Emacs
```

Scan the QR code in WhatsApp → Linked Devices. Session persists in `~/.local/share/wuzapi/`.

---

## What's still missing or deferred

### Wasabi (WhatsApp Emacs client)

`codeberg.org/vifon/wasabi` is a native Emacs WhatsApp frontend that sits on top of
wuzapi. Not in nixpkgs. Packaging it requires a `trivialBuild` derivation. The current
wuzapi functions (`my/wuzapi-create-user`, `my/wuzapi-connect`) are a minimal bridge
for initial setup only — they don't provide a conversation view.

When ready to pursue: research the repo coords, write `home/wuzapi.nix` with a
`trivialBuild` for wasabi, add a `use-package wasabi` block to config.org with evil
keybindings.

### org vault (`~/org/`)

The config has full org-roam, org-ql, org-gcal, and capture templates wired up, but
`~/org/` is mostly empty.

Currently the markdown vault is still used, but the ~/org/ directory is a possible future direction.

### nouwens.org email

The third email account (`thijmen@nouwens-lindemans.nl`) is declared in mu4e's
`mu4e-user-mail-address-list` but the actual mbsync sync for it needs verification
(`ls ~/Mail/Lindemans/INBOX/`). Check `home/email.nix` for the mbsync config.

### Email quality of life

mu4e is configured but not yet used daily — no muscle memory. Gaps to address when
it becomes a friction point:
- `h` key in headers mode (currently unbound — should go back or prev-unread)
- `gg` / first-message binding (omitted to avoid mapping complexity)
- HTML rendering via w3m — test with real messages
- no persistent side bar for different email addresses.

---

## Hardware note

```
card2 = Nvidia GTX 1060, PCI:1:0:0
Driver: legacy_535
KWIN_DRM_DEVICES fix is in hosts/desktop/default.nix — do NOT change
```

Monitors at 100% scaling → performance acceptable for Cairo/PGTK.

---

## Known annoyances


### 1. elfeed feeds automatic settings are quite difficult to parse

Currently (after fixing elfeed), I just see a large list of entries.
Nothing to identify them. 
The youtube feed is now a single-column layout with inline thumbnails — done 2026-07-05.

---

## Queued improvements

*Noted 2026-07-05 — not yet implemented. Implement one at a time.*

### Typst auto-render on buffer load

The typst math preview (`org-typst-preview-mode`) works when toggled manually.
To match Obsidian's behaviour, add a hook so all `$...$` fragments render when
the buffer is first loaded:

```elisp
(add-hook 'org-mode-hook #'org-typst-preview-mode)
;; optionally for markdown too:
;; (add-hook 'markdown-mode-hook #'org-typst-preview-mode)
```

One-liner in the existing `** Typst Math Preview` section of config.org.

### calfw — visual calendar

A week/month calendar grid (like a normal calendar app) to complement org-agenda.

- Nix packages to add to `home/emacs.nix`: `calfw` + `calfw-org`
- use-package block with `calfw-org`
- Integrates with org-gcal automatically (same agenda files)
- Suggested binding: `SPC a c` for the calfw week view

### Google Calendar frequent re-auth

org-gcal prompts for re-auth every few minutes when the plstore passphrase
is not cached across sessions. Two options:

1. **Longer gpg-agent TTL**: add to `~/.gnupg/gpg-agent.conf`:
   `default-cache-ttl 86400` (24h) and `max-cache-ttl 86400`
   Then restart: `gpgconf --kill gpg-agent`

2. **Plain authinfo**: move credentials from `~/.authinfo.gpg` to `~/.authinfo`
   (unencrypted). Acceptable given full-disk encryption on this machine.

### wuzapi 404 on create-user

`my/wuzapi-create-user` returns 404. Likely the admin token in `my/wuzapi-admin`
in config.org does not match what is in `~/.local/share/wuzapi/.env`.
Debug: `cat ~/.local/share/wuzapi/.env` and compare.

### Key repeat rate (hold-delay)

The perceived hold-delay difference between Emacs and kitty/neovim is a
system-level keyboard repeat rate, not an Emacs variable.
Fix: KDE → System Settings → Input Devices → Keyboard → Delay / Rate.
Reducing the delay (ms before repeat starts) will make held keys feel snappier.


