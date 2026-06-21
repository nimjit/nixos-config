# Email — aerc setup plan

## Goal

Replace Thunderbird with **aerc** (terminal TUI, keyboard-driven) handling two accounts:

| Account | Provider | Auth |
|---------|----------|------|
| `tidemanus@gmail.com` | Gmail | App password |
| `t.j.nouwens@student.tudelft.nl` | Microsoft 365 | OAuth2 via `oauth2ms` |

---

## Why aerc

- In nixpkgs; home-manager has `programs.aerc`
- Multi-account, vim-style keybindings
- IMAP + SMTP natively, built-in OAuth2
- Lighter than Thunderbird, stays in the terminal

---

## The OAuth2 problem with Microsoft 365

Microsoft dropped basic IMAP auth in 2023. `oauth2ms` (in nixpkgs) handles this:

1. One-time browser login → refresh token stored at `~/.config/oauth2ms/oauth2ms.json`
2. aerc calls `oauth2ms` at connect time for a fresh access token

---

## Packages to add

```nix
# modules/common.nix
aerc
oauth2ms
```

---

## `home/aerc.nix` (to create)

```nix
{ ... }: {
  programs.aerc = {
    enable = true;
    accounts = {
      Gmail = {
        source = "imaps://tidemanus@gmail.com@imap.gmail.com";
        source-cred-cmd = "lpass show --password 'Gmail App Password aerc'";
        outgoing = "smtps+plain://tidemanus@gmail.com@smtp.gmail.com:465";
        outgoing-cred-cmd = "lpass show --password 'Gmail App Password aerc'";
        default = "INBOX";
        from = "Thijmen <tidemanus@gmail.com>";
        copy-to = "[Gmail]/Sent Mail";
      };
      University = {
        source = "imaps+xoauth2://t.j.nouwens@student.tudelft.nl@outlook.office365.com";
        source-cred-cmd = "oauth2ms";
        outgoing = "smtp+xoauth2://t.j.nouwens@student.tudelft.nl@smtp.office365.com:587";
        outgoing-cred-cmd = "oauth2ms";
        default = "INBOX";
        from = "Thijmen Nouwens <t.j.nouwens@student.tudelft.nl>";
        copy-to = "Sent Items";
      };
    };
  };
}
```

---

## One-time setup

### Gmail app password

1. myaccount.google.com → Security → App passwords → create "aerc"
2. Store in LastPass: `lpass login thijmen.nouwens@gmail.com && lpass add 'Gmail App Password aerc'`

### Microsoft 365 OAuth2

```json
// ~/.config/oauth2ms/config.json (not in repo)
{
  "client_id": "d3590ed6-52b3-4102-aeff-aad2292ab01c",
  "tenant_id": "common",
  "username": "t.j.nouwens@student.tudelft.nl"
}
```

Run `oauth2ms` once interactively; browser opens → log in → token saved.

---

## Status

- [ ] Add aerc + oauth2ms to common.nix
- [ ] Create home/aerc.nix
- [ ] Run one-time Gmail app password setup
- [ ] Run one-time oauth2ms browser login
- [ ] Test both accounts in aerc
- [ ] Remove Thunderbird from packages once confirmed working
