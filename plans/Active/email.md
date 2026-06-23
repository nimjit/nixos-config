# Email — neomutt

## Goal

Terminal email for Gmail (working) and `thijmen@nouwens.org` (planned).
TU Delft uses browser.

| Account | Provider | Auth | Status |
|---------|----------|------|--------|
| Gmail | Gmail IMAP | App password via lpass | ✓ working |
| `thijmen@nouwens.org` | Self-hosted (dad's server) | lpass | planned |

---

## Architecture

```
mbsync (IMAP → maildir, every 5 min)
  ↓
~/Mail/
  Gmail/
    INBOX/
    [Gmail]/Verzonden berichten/
    [Gmail]/Concepten/
    [Gmail]/Prullenbak/
  Nouwens/          ← future

neomutt reads ~/Mail/
msmtp sends outgoing mail
mako shows new-mail notifications
```

---

## Current UI

```
┌──────────────────┬──────────────────────────────────────────────────┐
│ Gmail            │  # From               Subject              Date  │
│  INBOX      (12) │  * Alice              Re: meeting          14:03 │
│  Verzonden       │    Bob                Project update       13:45 │
│  Concepten       │                                                  │
│  Prullenbak      ├──────────────────────────────────────────────────┤
│                  │  From: Alice <alice@example.com>                 │
│                  │  To:   Thijmen                                   │
│                  │  Date: Mon 23 Jun 14:03                          │
│                  │                                                  │
│                  │  Hi Thijmen,                                     │
│  [?] help        │                                                  │
└──────────────────┴──────────────────────────────────────────────────┘
```

---

## Current key bindings

### Index

| Key | Action |
|-----|--------|
| `j` / `k` | Up / down |
| `l` / `Enter` | Open message |
| `gg` / `G` | First / last |
| `m` | Compose |
| `r` / `R` | Reply / reply-all |
| `d` | Delete |
| `u` | Toggle read/unread |
| `v` | View attachments |
| `gi` | Go to INBOX |
| `b` | Toggle sidebar |
| `?` | Key cheatsheet |

### Pager

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll |
| `q` | Back to index |
| `r` / `R` | Reply / reply-all |

### Sidebar

| Key | Action |
|-----|--------|
| `J` / `K` | Next / previous folder |
| `Ctrl+O` | Open highlighted folder |

---

## Secrets

Secrets live at `~/.config/nixos-secrets.nix` (outside the git repo).
`email.nix` imports it via absolute path; rebuild uses `--impure`.

```nix
{
  gmailAddress  = "you@gmail.com";
  nouwensAddress = "thijmen@nouwens.org";   # add when ready
}
```

Passwords via `lpass show --password 'Entry Name'` in `passwordCommand`.
`LPASS_AGENT_TIMEOUT=0` keeps the agent alive for the full login session.

---

## Adding an account (template)

```nix
accounts.email.accounts.Nouwens = {
  address         = s.nouwensAddress;
  userName        = s.nouwensAddress;
  realName        = "Thijmen Nouwens";
  imap            = { host = "mail.nouwens.org"; port = 993; tls.enable = true; };
  smtp            = { host = "mail.nouwens.org"; port = 465; tls = { enable = true; useStartTls = false; }; };
  passwordCommand = "lpass show --password 'Nouwens mail'";
  mbsync          = { enable = true; create = "maildir"; expunge = "both"; patterns = [ "INBOX" "Sent" "Drafts" "Trash" ]; };
  msmtp.enable    = true;
  neomutt         = { enable = true; extraMailboxes = [ "Sent" "Drafts" "Trash" ]; };
};
```

Then add a `gn` macro (go to Nouwens INBOX) and a `folder-hook` for the from address.

> **Note:** Gmail IMAP uses the account's UI language for folder names.
> Dutch: Verzonden berichten, Concepten, Prullenbak.
> Check with `mbsync -c /tmp/test.conf -l AccountName` using `Patterns *`.

---

## Status

- [x] Gmail account: mbsync + msmtp + neomutt sidebar
- [x] Secrets outside git (`~/.config/nixos-secrets.nix`, `--impure` rebuild)
- [x] Dutch folder names fixed
- [x] lpass session kept alive (`LPASS_AGENT_TIMEOUT=0`)
- [x] lpass-rofi shows clean entry names (Alt+P)
- [ ] Remove Thunderbird from `modules/common.nix` once comfortable
- [ ] Add `thijmen@nouwens.org` account

---

## Future work

### 1. Movement improvements

`Ctrl+O` to open a sidebar folder is awkward — requires leaving the keyboard home row.
Options:
- Remap to `o` or `Enter` in the sidebar map (not index/pager, where those keys are already used)
- Add `H` / `L` to jump left into sidebar / open highlighted folder
- Consider: `\n` (Enter in sidebar context) or a dedicated `<space>` to open

Also worth adding:
- `s` → save/move message to folder (currently unbound)
- `<Tab>` → jump between accounts (macro: `<change-folder>~/Mail/Gmail/INBOX<enter>` vs `~/Mail/Nouwens/INBOX`)

### 2. Colours

Stylix only sets foreground/background; neomutt has a rich colour system.
Apply per-element colours matching the Ukiyo palette (same approach as khal's `[palette]` section):

```
color index        yellow  default  ~N       # unread
color index        red     default  ~D       # deleted
color index        green   default  ~T       # tagged
color header       cyan    default  "^From:"
color header       cyan    default  "^Subject:"
color quoted       blue    default  "^>"
color signature    brightblack default ""
color attachment   magenta default  ""
```

Use `extraConfig` in `programs.neomutt`. Reference the Ukiyo base16 palette
(see `themes/ukiyo.nix`): gold e0ba86, amber ba945f, text ccc2b7, dark 413632,
green 9aad6e, red c72626.

### 3. Notifications

When mbsync pulls new mail, fire a `notify-send` via mako.
Options:
- Wrap mbsync in a shell script that compares "Near: +N" before/after
- Or use `services.mbsync.postExec` (if the home-manager option exists)
- Or a systemd `ExecStartPost=` on the mbsync service that runs a notify script

Script outline:
```bash
result=$(mbsync Gmail 2>&1)
new=$(echo "$result" | grep -oP 'Near: \+\K[0-9]+')
(( new > 0 )) && notify-send "📬 Mail" "$new new message(s)" --expire-time=5000
```

### 4. Greeting integration

Add an "Unread mail" line to `_greeting()` in `zsh.nix`, alongside the calendar
events and todo items. Position: after the schedule/todo columns, or as a third
column if unread count > 0.

```bash
unread=$(find ~/Mail/*/INBOX/new -type f 2>/dev/null | wc -l)
(( unread > 0 )) && printf '  %s✉ %d unread%s\n' "$GOLD" "$unread" "$RESET"
```

Could also add `email` or `mail` to the hint line at the bottom of the greeting
(currently: `today  vault-work  uni-work  messages  music  cal`).

### 5. Khal interoperability

Some emails contain calendar invites (`.ics` attachments). Neomutt can pipe
attachments to external commands. Possible workflow:

- `V` in attachment view → pipe `.ics` to `khal import` to add event to calendar
- Or auto-import via a mailcap rule:
  ```
  text/calendar; khal import %s; needsterminal
  ```
  Declare in `xdg.configFile."neomutt/mailcap"` and set `mailcap_path` in neomutt settings.

Also: neomutt can render HTML mail via `w3m` or `lynx` (already available as `wb`):
```
text/html; w3m -I utf-8 -T text/html %s; copiousoutput
```

### 6. Move subscriptions to nouwens.org

Goal: reduce Gmail dependency over time.

Process:
1. Set up `thijmen@nouwens.org` in neomutt first (so you can receive there)
2. Go through Gmail subscriptions / newsletters one by one:
   - Keep → re-subscribe with nouwens.org address
   - Cut → unsubscribe
3. Update accounts on important services (bank, government, etc.)
4. Forward Gmail to nouwens.org as a fallback during migration
5. Eventually set Gmail to auto-archive rather than inbox (or stop checking it)

No rush — treat it as background work. Tracking list could live in a vault note.

### 7. Other ideas

- **HTML rendering**: `w3m` mailcap rule (see §5) — many newsletters are HTML-only
- **Address book**: `abook` or `notmuch` for contact completion when composing
- **Search**: `notmuch` full-text search across all mailboxes (`/` currently only searches the current folder)
- **Spam filter**: `bogofilter` or `spamc` as a post-sync hook to auto-tag/move spam
- **Sent-mail deduplication**: Gmail server-saves a copy AND msmtp can save locally — check `set record` in neomutt to avoid duplicates
