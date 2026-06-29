# Emacs — Remaining Gaps

*Last updated: 2026-06-29. See emacs.md for full current-state reference.*

Nearly everything from the original gap list is implemented. What remains:

---

## First-time setup (not config — just commands to run)

- [ ] `mu init --maildir=~/Mail --my-address=tidemanus@gmail.com --my-address=thijmen.nouwens@gmail.com --my-address=thijmen@nouwens-lindemans.nl`
- [ ] `mu index`
- [ ] `M-x my/wuzapi-create-user` — creates wuzapi user, saves token to session
- [ ] `M-x my/wuzapi-connect` — fetches QR PNG; scan in WhatsApp → Linked Devices
- [ ] `M-x elfeed-update` — test that feeds actually load after setup

---

## Wasabi (WhatsApp Emacs client)

Full conversation view — not just QR setup. The wuzapi HTTP bridge is running and
the Emacs helper functions exist, but there's no message list / chat buffer yet.

`codeberg.org/vifon/wasabi` is the package. Not in nixpkgs; needs `trivialBuild`.

**When pursuing:**
1. Find repo coords (owner, latest rev, hash)
2. Add `trivialBuild` derivation to `home/wuzapi.nix` (alongside the Go derivation)
3. Add `use-package wasabi` block to config.org with evil keybindings
4. Update `my/dash-messages` to call `(wasabi)` instead of `my/wuzapi-connect`

---

## org vault

`~/org/` is largely empty. All org-based dashboard stubs become useful as notes
accumulate there:
- `my/vault-dashboard-org` — reads from `~/org/personal/`
- `my/uni-dashboard-org` — reads from `~/org/uni/`
- org-ql deadline queries (agenda files, `~/org/uni/`)
- org-roam daily notes (`~/org/daily/YYYY-MM-DD.org`)

No config change needed — the stubs are in place. Becomes relevant as the org
workflow grows.

---

## Port inventory (don't conflict)

| Port | Service |
|------|---------|
| 6600 | MPD |
| 8080 | New tab page |
| 8089 | wuzapi |
| 8384 | Syncthing web UI |
| 22000 | Syncthing file sync |
| 21027 | Syncthing discovery |
| 41641 | Tailscale |
