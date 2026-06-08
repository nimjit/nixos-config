# CLI Migration Plan

## Goal

Replace open browser tabs with focused terminal tools. Each item here is a browser
tab that runs continuously (WhatsApp Web, LastPass popup, Google Calendar, new tab
page) and can be replaced with something faster, keyboard-driven, and less RAM-heavy.

## Current state

All four packages are already in `modules/common.nix`:
- `nchat` — installed, not yet configured
- `lastpass-cli` — installed, not yet configured
- `calcurse` — installed, not yet configured
- New tab page — Tabliss still active; Tridactyl broken on it

---

## Tool 1 — nchat (WhatsApp)

### What it is

`nchat` is a terminal WhatsApp client that uses the `whatsmeow` library (the same
protocol WhatsApp Web uses). It gives desktop notifications without keeping a browser
tab open. Once paired, it runs headlessly and stays connected via a background
process or by launching it when needed.

### First-time pairing (one-time)

```bash
nchat
```

On first launch, nchat creates `~/.config/nchat/` and shows a QR code in the
terminal. Open WhatsApp on your phone → Settings → Linked Devices → Link a Device →
scan the QR code. The session is saved; you will not need to re-scan.

If the QR code doesn't render properly in kitty (too large), resize the terminal
window narrower before running.

### Key bindings inside nchat

nchat is a TUI. Default bindings:
- `j / k` — next / previous chat
- `Enter` — open selected chat
- `i` — enter compose mode
- `Escape` — back to chat list
- `q` — quit
- `Tab` — switch between chat list and message view
- `PageUp / PageDown` — scroll message history

All bindings are configurable in `~/.config/nchat/ui.conf`.

### Desktop notifications

nchat sends notifications via `libnotify` (notify-send) when it is not focused or
running in the background. On KDE this hits the KDE notification daemon. On Sway it
hits mako. No additional configuration needed.

To keep nchat running in the background so it receives notifications even when the
window is closed, run it inside a tmux session:

```bash
# In zsh config or as an alias:
alias messages="tmux new-session -A -s nchat nchat"
```

`tmux new-session -A -s nchat nchat` attaches to the existing nchat tmux session if
it's already running, or creates a new one. This way nchat is always running and
you just "attach" to check messages.

### NixOS config additions needed

Add tmux to packages if not already present (check `modules/common.nix`):
```nix
tmux
```

Add to `home/zsh.nix` (or wherever aliases are defined):
```nix
shellAliases = {
  messages = "tmux new-session -A -s nchat nchat";
};
```

Or as a shell function with a message:
```bash
messages() {
  if ! tmux has-session -t nchat 2>/dev/null; then
    echo "Starting nchat..."
    tmux new-session -d -s nchat nchat
  fi
  tmux attach-session -t nchat
}
```

### Open questions

- [ ] **nchat config**: check if `~/.config/nchat/ui.conf` needs vim-key remapping
      (some builds ship with arrow-key defaults; may need to remap j/k manually)
- [ ] **Multiple accounts**: if you have both personal and business WhatsApp, nchat
      supports multiple accounts via `nchat --profile <name>`. One session per profile.
- [ ] **Notification filtering**: if notification volume is too high, nchat allows
      per-chat mute. Check `~/.config/nchat/` docs after first run.

---

## Tool 2 — New Tab Page (replace Tabliss)

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

### Open questions

- [ ] **Which Firefox profile**: check `home/firefox.nix` for the active profile name
      before adding the `programs.firefox.profiles.default.settings` block
- [ ] **Tridactyl newtab setting**: Tridactyl has its own `set newtab <url>` command
      that overrides Firefox's new tab. If Tridactyl is managing the new tab, set it
      there instead: `:set newtab file:///home/thijmen/.config/firefox/newtab.html`
- [ ] **Tabliss removal**: uninstall Tabliss from Firefox after the new page is working

---

## Tool 3 — lastpass-cli

### What it is

`lpass` is the official LastPass CLI. It connects to the same vault as the browser
extension — no migration needed. The extension handles browser autofill; `lpass`
handles terminal access and scripting (rofi password picker, SSH key retrieval, etc.).

### First-time login (one-time)

```bash
lpass login tidemanus@gmail.com
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

### Rofi password picker script

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

## Tool 4 — calcurse + Google Calendar

### Context: calcurse vs org-gcal

Both calcurse and org-gcal (in Emacs) sync with Google Calendar. They serve different
contexts:
- **calcurse**: pure terminal, works without Emacs being open, fast TUI calendar
- **org-gcal**: syncs Google Calendar into org-agenda, useful when Emacs is your
  primary planning interface

The two can coexist — they sync the same Google Calendar independently. Use calcurse
for a quick terminal `what's on today` check; use org-agenda for planning and editing.
Both write to the same Google Calendar, so changes from either show up in the other
after the next sync.

### How calcurse stores data

calcurse uses three plain text files:
- `~/.local/share/calcurse/apts` — appointments (timed events)
- `~/.local/share/calcurse/todo` — TODO items
- `~/.local/share/calcurse/conf` — configuration

(Default location; can be overridden with `-D` flag.)

### calcurse-caldav setup (Google Calendar sync)

`calcurse-caldav` is shipped with calcurse. It syncs via Google's CalDAV endpoint.

**Step 1 — Google App Password** (required because calcurse uses Basic Auth):
1. Go to myaccount.google.com → Security
2. Enable 2-Step Verification if not already on
3. Search for "App passwords" → create one for "Other" → name it "calcurse"
4. Note the 16-character app password (shown once)

**Step 2 — Create calcurse-caldav config**:
```bash
mkdir -p ~/.config/calcurse/caldav
```

`~/.config/calcurse/caldav/config`:
```ini
[caldav]
hostname = apidata.googleusercontent.com
path     = /caldav/v2/tidemanus%40gmail.com/events/
authmethod = basic
username = tidemanus@gmail.com
password = <16-char-app-password>
insecuressl = No
```

Note: the email address in `path` must be URL-encoded (`@` → `%40`).

**Step 3 — First sync**:
```bash
# Pull from Google Calendar into calcurse (read-only test first)
calcurse-caldav --init keep-remote

# After verifying, do a full bidirectional sync:
calcurse-caldav
```

`--init keep-remote` on first run tells calcurse to trust Google's data and pull
everything down. Subsequent `calcurse-caldav` calls do a bidirectional sync.

**Step 4 — Sync before opening calcurse** (shell alias):
```bash
alias cal="calcurse-caldav --quiet && calcurse"
```

Add to `home/zsh.nix` shellAliases. This syncs silently before opening the TUI.

### calcurse key bindings (TUI)

calcurse opens with a three-panel view: calendar (left), appointments (top right),
TODO (bottom right). Focus switches with `Tab`.

- `h / l` — previous / next day (in calendar panel)
- `j / k` — navigate items in appointment/TODO panels
- `a` — add appointment
- `t` — add TODO item
- `d` — delete selected item
- `e` — edit selected item
- `s` — save
- `q` — quit
- `?` — help

### Syncthing consideration

calcurse data lives in `~/.local/share/calcurse/`. If you want calendar access on
the laptop as well, sync this directory via Syncthing. The files are plain text and
merge cleanly. Add to Syncthing as a folder shared between desktop and laptop.

Alternatively, rely purely on Google Calendar as the source of truth and just run
`calcurse-caldav` on each machine independently.

### Systemd timer for automatic sync (optional)

To keep calcurse in sync without running `cal` alias:

```nix
# In home/default.nix or a new home/calcurse.nix:
systemd.user.services.calcurse-sync = {
  Unit.Description = "Sync calcurse with Google Calendar";
  Service = {
    Type = "oneshot";
    ExecStart = "${pkgs.calcurse}/bin/calcurse-caldav --quiet";
  };
};

systemd.user.timers.calcurse-sync = {
  Unit.Description = "Sync calcurse every 15 minutes";
  Timer = {
    OnBootSec = "2min";
    OnUnitActiveSec = "15min";
    Persistent = true;
  };
  Install.WantedBy = [ "timers.target" ];
};
```

This runs `calcurse-caldav` every 15 minutes in the background. When you open
calcurse, it already has the latest events.

### Storing the app password securely

The app password in `~/.config/calcurse/caldav/config` is plain text. Mitigations:
- The file is `~/.config/calcurse/caldav/config` which is only readable by your user
  (mode 600 — set explicitly)
- If this is uncomfortable, calcurse-caldav also accepts the password via environment
  variable `CALCURSE_CALDAV_PASSWORD` — set it from `~/.authinfo.gpg` via a wrapper
  script

Plain text in a user-only config file is the standard approach for CalDAV clients
(Thunderbird, GNOME Calendar, etc. all do the same).

### Open questions

- [ ] **Google Calendar ID**: the `path` in caldav config uses the primary calendar
      (`tidemanus@gmail.com`). If you use multiple Google Calendars (work, personal,
      uni), each needs its own `path` or a separate caldav config. Find calendar IDs
      at: Google Calendar → Settings → calendar → scroll to "Calendar ID".
- [ ] **org-gcal duplication**: once org-gcal is set up in Emacs, both tools sync
      the same calendar. Test that creating an event in calcurse appears in org-agenda
      after a sync cycle. They should not conflict.
- [ ] **Laptop sync**: decide whether to replicate the caldav config on the laptop
      (same app password, same Google account) or just use Google Calendar web there.
