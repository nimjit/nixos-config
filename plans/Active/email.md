# Email — neomutt setup plan

## Goal

Replace Thunderbird with neomutt. Two accounts:

| Account | Provider | Auth |
|---------|----------|------|
| Gmail | Gmail | App password via LastPass |
| `@student.tudelft.nl` | Microsoft 365 | OAuth2 via davmail |

---

## Architecture

```
IMAP fetch       Send         OAuth2 bridge
─────────────    ──────────   ──────────────────
mbsync ──────────────────────── davmail (MS365 only)
  │              msmtp               │
  ▼                                  │
~/Mail/                        localhost:1143/1025
  Gmail/
  TUDelft/
      └── Inbox/
          Sent/
          Drafts/
          Trash/
```

- **mbsync** — syncs IMAP → local maildir on a systemd timer
- **msmtp** — sends outgoing mail
- **davmail** — local proxy for TU Delft; handles Microsoft OAuth2, presents plain
  IMAP/SMTP on localhost so mbsync doesn't need to deal with OAuth2
- **neomutt** — reads/writes the local maildir

Gmail connects directly. TU Delft goes through davmail on localhost:1143/1025.

---

## UI layout

```
┌──────────────────┬──────────────────────────────────────────────────┐
│ Gmail            │  # From               Subject              Date  │
│  Inbox      (12) │  * Alice              Re: meeting          14:03 │
│  Sent            │    Bob                Project update       13:45 │
│  Drafts          │    newsletter         Weekly digest        09:00 │
│  Trash           │                                                  │
│                  ├──────────────────────────────────────────────────┤
│ TU Delft         │  From: Alice <alice@example.com>                 │
│  Inbox       (3) │  To:   Thijmen                                   │
│  Sent            │  Date: Mon 23 Jun 14:03                          │
│  Trash           │                                                  │
│                  │  Hi Thijmen,                                     │
│                  │                                                  │
│                  │  Can we move the meeting to Thursday?            │
│                  │                                                  │
│  [?] help        │                                                  │
└──────────────────┴──────────────────────────────────────────────────┘
```

- Left sidebar: folder list per account, unread counts
- Top right: message index (list)
- Bottom right: pager (open message), appears when a message is selected
- `?` opens a personal cheatsheet (same pattern as yt-feed and dashboard)

Sidebar width ~20 cols. Stylix themes neomutt automatically.

---

## Key bindings (planned)

### Index (message list)

| Key | Action |
|-----|--------|
| `j` / `k` | Move up/down |
| `Enter` / `l` | Open message |
| `r` | Reply |
| `R` | Reply-all |
| `m` | Compose new |
| `d` | Delete (moves to Trash) |
| `s` | Save / move to folder |
| `u` | Mark unread |
| `Tab` | Switch account |
| `b` | Toggle sidebar |
| `?` | Key cheatsheet |

### Pager (reading a message)

| Key | Action |
|-----|--------|
| `j` / `k` | Scroll |
| `q` | Back to index |
| `r` | Reply |
| `d` | Delete |
| `v` | View attachments |

### Sidebar

| Key | Action |
|-----|--------|
| `J` / `K` | Move between folders |
| `Enter` | Open folder |

---

## Secrets

Email addresses are kept out of git in `home/secrets.nix` (gitignored):

```nix
# home/secrets.nix — create manually on each machine, never commit
{
  gmailAddress   = "you@gmail.com";
  tudelftAddress = "t.nouwens@student.tudelft.nl";
}
```

`home/email.nix` imports it:

```nix
let s = import ./secrets.nix; in {
  accounts.email.accounts.Gmail.address = s.gmailAddress;
  ...
}
```

Passwords are never in the config — `passwordCommand` calls `lpass` at runtime.
OAuth2 tokens are stored by davmail outside the repo.

---

## Adding an account

Add a block to `home/email.nix` under `accounts.email.accounts`, add the address
to `home/secrets.nix`, then `rebuild`. mbsync will create the local folders on
next sync. For Microsoft 365 accounts: point imap/smtp at davmail localhost instead.

```nix
accounts.email.accounts.WorkClient = {
  address    = s.workAddress;   # add to secrets.nix
  realName   = "Thijmen Nouwens";
  imap.host  = "imap.workclient.com";
  smtp.host  = "smtp.workclient.com";
  mbsync     = { enable = true; create = "maildir"; };
  neomutt    = { enable = true; };
  passwordCommand = "lpass show --password 'WorkClient email'";
};
```

---

## Files to create

```
home/
  email.nix          # accounts.email + neomutt + mbsync + msmtp config
```

---

## One-time setup (manual, not in nix)

### Gmail app password
1. myaccount.google.com → Security → App passwords → create "neomutt"
2. `lpass add 'Gmail App Password neomutt'`

---

## Future work

### Additional accounts
- `thijmen@nouwens.org` — self-hosted mail server (run by dad); goal is to move
  more things here from Gmail over time. Add as a plain IMAP account (no OAuth2,
  no davmail needed). Credentials via LastPass.

### Email organisation
- Filter and route incoming mail more deliberately rather than everything landing
  in one inbox. Consider neomutt hooks or server-side filters once accounts are stable.

### lpass-rofi (`Alt+P`) display fix
- Each entry currently shows a hash prefix before the name (LastPass entry ID).
  Fix the display format in `home/dotfiles/lpass-rofi.sh` to strip the ID.

---

## Status

- [x] Create `home/secrets.nix` with email addresses (manual, not in git)
- [x] Create `home/email.nix` — accounts, mbsync, msmtp, neomutt, cheatsheet
- [x] Wire into `home/default.nix`
- [x] Gmail app password stored in LastPass
- [x] Rebuild successful — neomutt opens, Gmail INBOX visible
- [ ] Investigate `[Gmail]/Sent Mail` etc. not syncing (mbsync only syncs INBOX so far)
- [ ] Remove Thunderbird from `modules/common.nix` once confirmed working

> **Note:** TU Delft (@student.tudelft.nl) was attempted via davmail (MS365 OAuth2 proxy)
> but dropped — OAuth2 browser flow and IMAP auth issues made it unreliable. Use browser for uni mail.
