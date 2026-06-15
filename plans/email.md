# Email — aerc setup plan

## Goal

Replace Thunderbird with **aerc** (terminal TUI, keyboard-driven) handling two accounts:

| Account | Provider | Auth |
|---------|----------|------|
| `tidemanus@gmail.com` | Gmail | App password (or OAuth2) |
| `name@university.nl` | Microsoft 365 | OAuth2 via `oauth2ms` |

---

## Why aerc

- In nixpkgs; home-manager has `programs.aerc`
- Multi-account, vim-style keybindings
- Handles IMAP + SMTP natively
- Built-in OAuth2 support via `oauthbearer`/`xoauth2`
- Lighter than Thunderbird, stays in the terminal

Alternatives considered: neomutt (more powerful but longer config), himalaya (CLI-first, weaker TUI).

---

## The OAuth2 problem with Microsoft 365

Microsoft dropped basic IMAP auth in 2023. Connecting to `outlook.office365.com`
now requires an OAuth2 Bearer token. `oauth2ms` (in nixpkgs) handles this:

1. One-time browser login → `oauth2ms` stores a refresh token locally
2. aerc calls `oauth2ms` at connect time to get a fresh access token
3. Thereafter fully automatic

The refresh token is stored at `~/.config/oauth2ms/oauth2ms.json`.
It is **not** committed to the repo (contains credentials).

Gmail can also do OAuth2 but an app password is simpler and avoids needing a second helper.

---

## Packages to add (`modules/common.nix`)

```nix
aerc        # TUI email client
oauth2ms    # Microsoft 365 OAuth2 token helper
```

---

## `home/aerc.nix` (new file)

```nix
{ ... }: {
  programs.aerc = {
    enable = true;
    # accounts.conf — contains no secrets (passwords come from commands)
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
        source = "imaps+xoauth2://YOUR_UNI_EMAIL@outlook.office365.com";
        source-cred-cmd = "oauth2ms";
        outgoing = "smtp+xoauth2://YOUR_UNI_EMAIL@smtp.office365.com:587";
        outgoing-cred-cmd = "oauth2ms";
        default = "INBOX";
        from = "Thijmen <YOUR_UNI_EMAIL>";
        copy-to = "Sent Items";
      };
    };
  };
}
```

Add to `home/default.nix` imports: `./aerc.nix`

---

## One-time setup steps (interactive, can't be automated)

### Gmail app password

1. Go to myaccount.google.com → Security → 2-Step Verification → App passwords
2. Create one named "aerc"
3. Store it in LastPass: `lpass add 'Gmail App Password aerc'` with the password field set
4. The `source-cred-cmd` in aerc.nix will pull it automatically

### Microsoft 365 OAuth2

`oauth2ms` needs to know your tenant and a client ID. The client ID can be Microsoft's
own or a registered app. For most university tenants the community client ID works:

```ini
# ~/.config/oauth2ms/config.json  (create manually, not in repo)
{
  "client_id": "d3590ed6-52b3-4102-aeff-aad2292ab01c",
  "tenant_id": "common",
  "username": "YOUR_UNI_EMAIL"
}
```

Then run once interactively:
```
oauth2ms
```
A browser window opens → log in with university credentials → token saved.

After that `oauth2ms` (called by aerc on each connect) refreshes silently.

---

## Open questions

- Fill in `YOUR_UNI_EMAIL` in aerc.nix once known
- The university tenant ID may need to be specific (find at
  `login.microsoftonline.com/YOUR_UNI_EMAIL/.well-known/openid-configuration`)
- If the university blocks the community client ID, a custom Azure app registration
  is needed (requires admin or self-service portal)
- `lpass show` requires being logged in (`lpass login tidemanus@gmail.com`); add
  `lpass login` to the startup or use a keyring instead

---

## Status

- [ ] Fill in university email address
- [ ] Add aerc + oauth2ms to common.nix
- [ ] Create home/aerc.nix
- [ ] Run one-time Gmail app password setup
- [ ] Run one-time oauth2ms browser login
- [ ] Test both accounts in aerc
- [ ] Remove Thunderbird from packages once confirmed working
