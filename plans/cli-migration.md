# CLI Migration Plan

## Goal

Replace open browser tabs with focused terminal tools. Each item here is a browser
tab that runs continuously (WhatsApp Web, LastPass popup, Google Calendar, new tab
page) and can be replaced with something faster, keyboard-driven, and less RAM-heavy.

## Current state

- `nchat` — installed and working; `messages()` opens/focuses a dedicated kitty tab
- `lastpass-cli` — installed; `LPASS_CLIPBOARD_COMMAND=wl-copy` set in zsh; no rofi script yet
- Calendar — **replaced calcurse with khal + vdirsyncer**; all 12 Google Calendars syncing; `cal` alias works
- New tab page — done; localhost:8080 server, New Tab Override extension pointing at it
- Music — MPD + rmpc installed; `<leader>m` neovim split works great; `music()` shell function has a bug (see Tool 5)
- Neovim dashboard — vault and uni dashboards working via `WorkflowVault`/`WorkflowUni`; `:Dashboard`/`<leader>D` return from any buffer
- Typst rendering — `<leader>tp` / `<leader>ta` work; math blocks `$...$` and `$$...$$` supported
- PDF split viewer — implemented but broken (see Bugs section below)

---

## Tool 1 — nchat (WhatsApp)

### What it is

`nchat` is a terminal WhatsApp client that uses the `whatsmeow` library (the same
protocol WhatsApp Web uses). It gives desktop notifications without keeping a browser
tab open. Once paired, it runs headlessly and stays connected via a background
process or by launching it when needed.

### First-time pairing (one-time) - Done

```bash
nchat
```

On first launch, nchat creates `~/.config/nchat/` and shows a QR code in the
terminal. Open WhatsApp on your phone → Settings → Linked Devices → Link a Device →
scan the QR code. The session is saved; you will not need to re-scan.

If the QR code doesn't render properly in kitty (too large), resize the terminal
window narrower before running.

### Key bindings inside nchat

nchat is a TUI. Bindings:
- `ctrl+ j / k` — next / previous chat
- `Enter` — open selected chat
- `i` — enter compose mode
- `Escape` — back to chat list
- `q` — quit
- `Tab` — switch between chat list and message view
- `PageUp / PageDown` — scroll message history

All bindings are configurable in `~/.config/nchat/ui.conf`.

I want them more neovim like:
nchat is a TUI. Bindings:
- `ctrl+ h / l` — move between chat content and chats list
- `Enter/ l` — open selected chat
- `i` — enter compose mode
- `Escape` — back to normal mode
- `:q` — quit
- `j / k` — scroll message history
Check init.lua - the neovim config - for keybindings.

### Desktop notifications

nchat sends notifications via `libnotify` (notify-send) when it is not focused or
running in the background. On KDE this hits the KDE notification daemon. On Sway it
hits mako. No additional configuration needed.

To keep nchat running in the background so it receives notifications even when the
window is closed, running it inside a tmux session is an option:

```bash
# In zsh config or as an alias:
alias messages="tmux new-session -A -s nchat nchat"
```

`tmux new-session -A -s nchat nchat` attaches to the existing nchat tmux session if
it's already running, or creates a new one. This way nchat is always running and
you just "attach" to check messages.

### NixOS config — done

No tmux needed. `messages()` is a shell function in `home/zsh.nix` that uses kitty remote control:

```bash
messages() {
  kitty @ focus-tab --match title:nchat 2>/dev/null || \
    kitty @ launch --type=tab --tab-title nchat nchat 2>/dev/null || \
    nchat
}
```

Focuses the existing nchat tab if open, otherwise opens a new one. Falls back to current terminal if kitty remote control is unavailable. Kitty remote control is enabled in `home/kitty.nix`.

### Open questions

- [ ] **nchat config**: check if `~/.config/nchat/ui.conf` needs vim-key remapping
      (some builds ship with arrow-key defaults; may need to remap j/k manually)
- [ ] **Notification filtering**: if notification volume is too high, nchat allows
      per-chat mute. Check `~/.config/nchat/` docs after first run.
- [ ] Multiple accounts: is it also possible to use nchat for different chatting apps, other than       whatsapp?
---

## Tool 2 — New Tab Page (replace Tabliss) - Done 

### The problem

Tabliss renders its new tab at a `moz-extension://` URL. Firefox's security model
prevents other extensions (including Tridactyl) from injecting content into
`moz-extension://` pages. Result: Tridactyl's hints, command bar, and vim bindings
are dead on every new tab.

### The fix

Replace Tabliss with a static HTML file served from `file://`. Tridactyl works on
`file://` pages. The HTML file replicates what Tabliss showed: a clock and a set of
quick links.

### Setting the new tab URL in Firefox

Firefox removed the `browser.newtab.url` user preference in Firefox 41. The cleanest
current approach is one of:

**Option A — "New Tab Override" extension**: A minimal extension (~3KB) whose only
job is to set the new tab page to a custom URL. It does NOT itself render the new
tab — it immediately redirects to the `file://` path you specify. Tridactyl works on
the destination `file://` page. Install from addons.mozilla.org (extension ID:
`newtaboverride@agenedia.com`). Configure via the extension settings:
`file:///home/thijmen/.config/firefox/newtab.html`

**Option B — `user.js` via home-manager**: Force Firefox to open a blank about:blank
new tab and set the home button to the file:

```nix
# In home/firefox.nix:
programs.firefox.profiles.default.settings = {
  "browser.newtabpage.enabled"        = false;   # blank new tab
  "browser.startup.homepage"          = "file:///home/thijmen/.config/firefox/newtab.html";
  "browser.startup.page"              = 1;        # open homepage on startup
};
```

This makes new tabs blank (fast) and the browser home button/startup loads the file.
New tab is blank but Tridactyl works on it. The newtab.html becomes a "home page"
you open with `SPC h` in Tridactyl or Super+Home.

Option B is recommended: no extra extension dependency, new tab opens instantly
(blank is the fastest possible new tab), and you use the home page for the dashboard
when you want it.

### The HTML file

Create `home/dotfiles/firefox/newtab.html` and link it via home-manager:

```nix
# In home/default.nix or home/firefox.nix:
xdg.configFile."firefox/newtab.html".source = ./dotfiles/firefox/newtab.html;
```

Content — a minimal dark page matching the ukiyo palette with a live clock and
configurable quick links:

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>New Tab</title>
<style>
  :root {
    --bg:      #372d29;
    --fg:      #ccc2b7;
    --accent:  #d4956a;
    --dim:     #868074;
    --link-bg: #2e2622;
  }
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    background: var(--bg);
    color: var(--fg);
    font-family: "JetBrains Mono", monospace;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    gap: 2rem;
  }
  #clock {
    font-size: 4rem;
    color: var(--accent);
    letter-spacing: 0.05em;
    font-weight: 300;
  }
  #date {
    font-size: 1rem;
    color: var(--dim);
    letter-spacing: 0.1em;
    text-transform: lowercase;
  }
  .links {
    display: flex;
    flex-wrap: wrap;
    gap: 0.75rem;
    justify-content: center;
    max-width: 700px;
  }
  .links a {
    background: var(--link-bg);
    color: var(--fg);
    text-decoration: none;
    padding: 0.4rem 1rem;
    border-radius: 2px;
    font-size: 0.85rem;
    transition: color 0.1s;
  }
  .links a:hover { color: var(--accent); }
  .section-label {
    color: var(--dim);
    font-size: 0.7rem;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    text-align: center;
  }
  .section { display: flex; flex-direction: column; gap: 0.5rem; align-items: center; }
</style>
</head>
<body>
<div id="clock">00:00</div>
<div id="date"></div>

<div class="section">
  <div class="section-label">daily</div>
  <div class="links">
    <a href="https://mail.google.com">mail</a>
    <a href="https://calendar.google.com">calendar</a>
    <a href="https://github.com/nimjit">github</a>
    <a href="https://web.whatsapp.com">whatsapp</a>
  </div>
</div>

<div class="section">
  <div class="section-label">uni</div>
  <div class="links">
    <a href="https://brightspace.tudelft.nl">brightspace</a>
    <a href="https://webmail.tudelft.nl">tudelft mail</a>
    <a href="https://studiegids.tudelft.nl">studiegids</a>
  </div>
</div>

<div class="section">
  <div class="section-label">tools</div>
  <div class="links">
    <a href="https://claude.ai">claude</a>
    <a href="https://chat.openai.com">gpt</a>
    <a href="https://arxiv.org">arxiv</a>
    <a href="https://scholar.google.com">scholar</a>
  </div>
</div>

<script>
function pad(n) { return n < 10 ? '0' + n : n; }
function tick() {
  const now = new Date();
  document.getElementById('clock').textContent =
    pad(now.getHours()) + ':' + pad(now.getMinutes());
  document.getElementById('date').textContent =
    now.toLocaleDateString('en-GB', { weekday:'long', day:'numeric', month:'long', year:'numeric' });
}
tick();
setInterval(tick, 1000);
</script>
</body>
</html>
```

### What to update

- Replace the quick links with your actual most-used sites
- Add/remove sections as needed
- The WhatsApp link in "daily" can be removed once nchat is the primary interface
- Colors are hardcoded to ukiyo palette; update `--bg`, `--fg`, `--accent` if the
  theme changes
- The typography is a bit small, check tabliss.json in /home/thijmen/Documents/BACKUP/Ricing for a more detailed comparisson.

### Open questions

- [ ] **Which Firefox profile**: check `home/firefox.nix` for the active profile name
      before adding the `programs.firefox.profiles.default.settings` block
- [ ] **Tridactyl newtab setting**: Tridactyl has its own `set newtab <url>` command
      that overrides Firefox's new tab. If Tridactyl is managing the new tab, set it
      there instead: `:set newtab file:///home/thijmen/.config/firefox/newtab.html`
- [ ] **Tabliss removal**: disable Tabliss from Firefox after the new page is working
      Do not uninstall, because other computers still use this extension on the same firefox account.

---

## Tool 3 — lastpass-cli

### What it is

`lpass` is the official LastPass CLI. It connects to the same vault as the browser
extension — no migration needed. The extension handles browser autofill; `lpass`
handles terminal access and scripting (rofi password picker, SSH key retrieval, etc.).

### First-time login (one-time)

```bash
lpass login thijmen.nouwens@gmail.com
```

This prompts for your LastPass master password. If 2FA is enabled, it will ask for
the OTP. After login, the session is cached in `~/.lpass/`. The session duration
depends on LastPass settings but typically stays valid for days.

```bash
lpass status          # check if logged in
lpass sync            # force sync with LastPass servers
lpass logout          # log out and clear local cache
```

### Common commands

```bash
# List all entries (formatted: Name [id: 12345])
lpass ls

# Show entry details
lpass show "Gmail"
lpass show --password "Gmail"     # just the password, to stdout
lpass show --username "Gmail"     # just the username
lpass show --url "Gmail"          # just the URL

# Copy password directly to clipboard (wl-clipboard on Wayland)
lpass show --clip "Gmail"

# Search
lpass ls | grep -i "bank"

# Create / edit (opens in $EDITOR)
lpass add "New Entry"
lpass edit "Existing Entry"
```

On Wayland, `--clip` uses `xclip` by default. Override to use `wl-copy`:
```bash
LPASS_CLIPBOARD_COMMAND="wl-copy" lpass show --clip "Gmail"
```

Add to `home/zsh.nix` environment or as a function:
```nix
sessionVariables.LPASS_CLIPBOARD_COMMAND = "wl-copy";
```

### Rofi password picker script - Requires Rofi

A script that fuzzy-searches your LastPass vault via rofi and copies the selected
password to the clipboard. Trigger with a keyboard shortcut.

Create `home/dotfiles/scripts/lpass-rofi.sh`:
```bash
#!/usr/bin/env bash
# lpass-rofi: fuzzy-pick a LastPass entry and copy its password to clipboard

# Ensure we're logged in
if ! lpass status --quiet 2>/dev/null; then
  notify-send "LastPass" "Not logged in. Run: lpass login tidemanus@gmail.com"
  exit 1
fi

# List entries, strip the [id: XXXXX] suffix for display
entries=$(lpass ls --long 2>/dev/null | grep -v "^(none)$")
if [ -z "$entries" ]; then
  notify-send "LastPass" "Vault is empty or sync failed"
  exit 1
fi

# Rofi picker — show name only, keep full line for parsing
selected=$(echo "$entries" | \
  rofi -dmenu -p "Password:" -i \
       -theme-str 'window {width: 500px;}' \
       -format 'i' 2>/dev/null)

if [ -z "$selected" ]; then exit 0; fi

# Get the entry name from the selected line
name=$(echo "$entries" | sed -n "$((selected+1))p" | sed 's/ \[id:.*\]//')

# Copy password
lpass show --clip "$name" 2>/dev/null && \
  notify-send "LastPass" "Copied: $name" --expire-time=3000
```

Make executable and link via home-manager:
```nix
home.file.".local/bin/lpass-rofi" = {
  source = ./dotfiles/scripts/lpass-rofi.sh;
  executable = true;
};
```

### Keyboard shortcut

**In KDE Plasma**: System Settings → Shortcuts → Custom Shortcuts → New → Global Shortcut →
Command/URL: `/home/thijmen/.local/bin/lpass-rofi` → assign a key (e.g. Super+P).

**In Sway** (when switching): add to `home/sway.nix` keybindings:
```nix
"${mod}+p" = "exec /home/thijmen/.local/bin/lpass-rofi";
```

### Open questions

- [ ] **Vault sync frequency**: `lpass sync` pulls latest from LastPass servers. The CLI
      does NOT auto-sync. Consider adding a cron/timer that runs `lpass sync` daily, or
      just sync manually before using the picker.
- [ ] **2FA interaction**: on first login and periodically, LastPass may require 2FA.
      The script gracefully notifies via notify-send if not logged in. Users must then
      run `lpass login` in a terminal to re-authenticate.
- [ ] **wl-clipboard dependency**: confirm `wl-clipboard` is in packages (it should
      be from the Sway migration additions). If not yet installed, `lpass --clip` will
      silently fail on Wayland.

---

## Tool 4 — khal + vdirsyncer (Google Calendar) ✓ Done

### What was built

calcurse was abandoned — it only syncs one calendar path at a time. Replaced with:
- **khal** — TUI calendar (`ikhal`), multi-calendar aware, themed with Ukiyo 256-colour palette
- **vdirsyncer** — syncs all 12 Google Calendars to `~/.local/share/calendars/` via CalDAV + OAuth2

`cal` alias in `home/zsh.nix`: `vdirsyncer sync > /dev/null 2>&1 && ikhal`

khal config managed by home-manager at `home/dotfiles/khal/config` → `~/.config/khal/config`.
vdirsyncer config is manual at `~/.config/vdirsyncer/config` (not in git — contains OAuth credentials
and gets modified by `vdirsyncer discover` on each new calendar added).

### vdirsyncer architecture

Google's CalDAV discovery only returns owned calendars. Shared calendars require separate
pair+storage entries with explicit CalDAV URLs.

**Main pair** (`[pair calendar]`): discovers owned calendars automatically via `["from a", "from b"]`.

**Shared calendar pairs**: one pair per shared calendar, each with `collections = ["from b"]` and
an explicit `url = "https://apidata.googleusercontent.com/caldav/v2/CALENDAR_ID/"`.

Calendars currently syncing (12 total):
- Work, Sport, Fun, Semi-productive, Mindfullness, Feestdagen (owned)
- D&D in Space, Lisan Shared 2, Lisan + Thijmen (writer access)
- Bolk: Algemeen, TU Delft timetable (reader access)
- Sport (cp7ljbsac30...) — unknown origin, syncs fine

Google Calendar API (JSON, `calendar.googleapis.com`) must be enabled in Google Cloud Console
project 106728458834 in addition to the CalDAV API — needed to list shared calendar IDs.

### Remaining / open

- [ ] **khal look** — the TUI works but the visual style needs refinement. The Ukiyo palette
      is applied but the overall layout/feel could be better. Explore khal themes and layout
      options; check the khal 0.14 changelog for any new theme keys.
- [ ] **org-gcal**: once Emacs org-gcal is set up, test that it reads the same calendars
      without conflicting with vdirsyncer. They can coexist since vdirsyncer is the write path.
- [ ] **Laptop sync**: replicate `~/.config/vdirsyncer/config` (with the same OAuth token or
      a fresh OAuth flow) on the laptop when needed.

---

## Tool 5 — Music (MPD + rmpc) — Partially done

### What was built

- MPD service running via `home/mpd.nix`; music directory: `~/Documents/BACKUP/Music`
- `rmpc` for TUI with album art via kitty graphics protocol
- `mpc` for CLI control (toggle, next, prev)
- `<leader>m` in neovim opens a 55-column vsplit terminal with rmpc; auto-queues the
  full library and shuffles if the queue is empty

### Bug — `music()` shell function opens empty queue

The `music()` shell function in `home/zsh.nix` has the same auto-queue logic as the
neovim keymap, but when launched via kitty tab it opens with an empty queue. The
neovim `<leader>m` split works correctly.

Likely cause: the `mpc add / && mpc shuffle && mpc play` command in the shell function
runs in the parent shell before the kitty tab opens, but rmpc in the new tab doesn't
see the populated queue (timing or state issue).

**To fix**: either run the mpc commands inside the new kitty tab's shell, or add a
short delay, or use `kitty @ launch --env` to pass a flag that triggers the queue fill.

### Open

- [ ] Fix `music()` shell function so it auto-queues before opening rmpc in the kitty tab
- [ ] Consider a systemd user timer to auto-sync the music library (`mpc update`) periodically

---

## Bugs / known issues

### image.nvim — magick_cli cannot open temp PNG

Error appears as a Lua callback when image.nvim tries to display an image:

```
magick_cli.lua:36: identify: unable to open image '/tmp/nvim.thijmen/.../...-source.png':
No such file or directory @ error/blob.c/OpenBlob/3683.
```

The file is written to `/tmp/nvim.thijmen/` but image.nvim's `magick_cli` processor
tries to open it before it exists (race condition), or the path it receives is stale.

Possible causes:
- image.nvim is receiving a path to a file that was already cleaned up
- The `magick_cli` processor is being called for a file type it shouldn't handle
- A temp file from a previous nvim session is being referenced

**To investigate**: check if the error only appears for specific file types or on specific
operations (`<leader>tp`, markdown images, etc.). May be worth trying the `magick_rock`
backend instead of `magick_cli` in image.nvim setup.

### PDF split viewer — pixel reporting unsupported

The in-neovim PDF viewer (`<leader>z`) uses `pdftoppm` + `kitten icat` in a vsplit
terminal. On the current setup it fails with:

```
Error: Terminal does not support reporting screen sizes in pixels,
use a terminal such as kitty, WezTerm, Konsole, etc.
```

This is unexpected since kitty is the terminal. Possible causes:
- The neovim `:terminal` buffer does not pass through kitty's pixel-size reporting to
  the inner process — `kitten icat` is running inside a neovim terminal, not directly
  in kitty, so it can't query kitty's pixel dimensions
- `TERM` or `KITTY_WINDOW_ID` env vars may not be available inside `:terminal`

**Fix approaches**:
1. Use `kitten icat --transfer-mode=file` which doesn't need pixel reporting
2. Or open the PDF viewer in a real kitty tab/window (not a neovim :terminal split),
   similar to how `music()` and `messages()` work
3. Or switch to sixel output which has different size negotiation

The neovim split approach may fundamentally not work for pixel-based rendering inside
`:terminal`. Option 2 (open as a kitty tab) is probably the cleanest fix.
