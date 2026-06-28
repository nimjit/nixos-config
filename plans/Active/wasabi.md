# Wasabi — Emacs WhatsApp client

## Overview

**Wasabi** is a native Emacs interface for WhatsApp.
**wuzapi** is the Go daemon it talks to — a JSON-RPC bridge to WhatsApp via the
whatsmeow library (same library as nchat). wuzapi runs in the background persistently;
Wasabi is the Emacs UI on top of it.

Architecture:
```
WhatsApp ↔ wuzapi (Go daemon, local HTTP/JSON-RPC) ↔ Wasabi (Emacs package)
```

---

## Step 1 — Find the repos

Before writing any Nix, confirm exact GitHub coordinates:

- **wuzapi**: likely `asterisk/wuzapi` or `tulir/wuzapi` on GitHub — verify, then note
  the commit hash you want to pin to
- **Wasabi**: search MELPA or GitHub for "wasabi emacs whatsapp" — note whether it is
  on MELPA (then nixpkgs may already have it as `epkgs.wasabi`) or only on GitHub

Run `nix-env -qaP | grep -i wasabi` or check
`https://search.nixos.org/packages?query=wasabi` and
`https://search.nixos.org/packages?query=wuzapi` to see if either is already packaged.

---

## Step 2 — Package wuzapi in Nix

wuzapi is almost certainly not in nixpkgs. Add it as a custom derivation.

In `home/dotfiles/wuzapi/` (or directly in `modules/`), create `wuzapi.nix`:

```nix
{ pkgs }:

pkgs.buildGoModule {
  pname = "wuzapi";
  version = "0.x.x";   # fill in from the release tag

  src = pkgs.fetchFromGitHub {
    owner = "OWNER";    # fill in from Step 1
    repo  = "wuzapi";
    rev   = "COMMIT_OR_TAG";
    hash  = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    # get hash via: nix-prefetch-url --unpack https://github.com/OWNER/wuzapi/archive/COMMIT.tar.gz
  };

  vendorHash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
  # get vendorHash by running the build once — Nix will error with the correct hash
}
```

Then reference it in `home/default.nix` or `modules/common.nix`:

```nix
{ pkgs, ... }:
let wuzapi = pkgs.callPackage ./wuzapi.nix { inherit pkgs; }; in
{
  home.packages = [ wuzapi ];
  # or: environment.systemPackages = [ wuzapi ];
}
```

---

## Step 3 — wuzapi systemd user service

wuzapi needs to run persistently in the background. Add a Home Manager systemd
user service so it starts on login and restarts on failure.

In `home/default.nix` (or a new `home/wasabi.nix` imported from there):

```nix
systemd.user.services.wuzapi = {
  Unit = {
    Description = "wuzapi WhatsApp JSON-RPC bridge";
    After = [ "network.target" ];
  };
  Service = {
    ExecStart = "${wuzapi}/bin/wuzapi";  # adjust binary name if needed
    Restart = "on-failure";
    RestartSec = "5s";
    # wuzapi stores session data; set a stable working directory
    WorkingDirectory = "%h/.local/share/wuzapi";
  };
  Install.WantedBy = [ "default.target" ];
};
```

Also ensure the data directory exists (add to `home.activation` or just let wuzapi
create it on first run — check the wuzapi README).

First-run pairing: wuzapi requires a QR-code scan to link the WhatsApp account.
Check the wuzapi docs for how to trigger this (likely a one-time HTTP call or CLI flag).

---

## Step 4 — Add Wasabi to emacs.nix

If Wasabi is on MELPA / in nixpkgs:

```nix
# in home/emacs.nix extraPackages list:
wasabi
```

If Wasabi is only on GitHub (not yet in nixpkgs), use `trivialBuild`:

```nix
(epkgs.trivialBuild {
  pname = "wasabi";
  version = "0.x.x";
  src = pkgs.fetchFromGitHub {
    owner = "OWNER";   # fill in from Step 1
    repo  = "wasabi";
    rev   = "COMMIT";
    hash  = "sha256-...";
  };
  packageRequires = [ epkgs.websocket ];   # adjust deps based on wasabi's Package-Requires header
})
```

---

## Step 5 — config.org section

Add a new `* Messages (Wasabi)` section in `config.org`:

```elisp
(use-package wasabi
  :init
  ;; Point Wasabi at the running wuzapi daemon.
  ;; Default port is 8080 — change if wuzapi is configured differently.
  (setq wasabi-wuzapi-url "http://localhost:8080")

  :config
  ;; Evil keybindings — check whether evil-collection has a wasabi entry first.
  ;; If not, define them manually:
  (evil-define-key 'normal wasabi-mode-map
    "j"  #'wasabi-next-message
    "k"  #'wasabi-prev-message
    "h"  #'wasabi-back           ; or wasabi-close-chat — check exact function names
    "l"  #'wasabi-open-chat
    "g"  #'wasabi-goto-first
    "G"  #'wasabi-goto-last
    "q"  #'bury-buffer
    "?"  #'wasabi-help)

  ;; Theme: if Wasabi hardcodes face colours, override them here
  ;; to align with Ukiyo. Check what faces wasabi defines after loading:
  ;;   M-x customize-group RET wasabi RET
  ;; Then add face overrides like:
  ;;   (set-face-attribute 'wasabi-message-face nil :foreground "#c4a882")
  )

;; Wire up the SPC leader
(spc! "W" '(wasabi :wk "whatsapp"))
```

**Function names are placeholders** — look them up from the Wasabi README or
`C-h f wasabi-` after loading the package.

---

## Step 6 — Fix the dashboard button

Currently `my/dash-messages` tries to attach to an nchat dtach session. Replace it:

```elisp
(defun my/dash-messages ()
  (interactive)
  (wasabi))   ; or whatever the entry-point command is
```

---

## Open questions (check before executing)

1. Exact GitHub repo owner/name for wuzapi and wasabi
2. Is wasabi on MELPA? (`M-x package-list-packages` or check melpa.org)
3. What port does wuzapi listen on by default?
4. Does wuzapi need any environment variables (phone number, API key) at first run?
5. Does evil-collection already include a wasabi entry?
6. What faces does wasabi define? Do they inherit standard Emacs faces or are they
   hardcoded? (Determines how much manual theming is needed.)
7. Can wuzapi's working directory / data path be configured via flag, so it can be
   set somewhere clean like `~/.local/share/wuzapi`?
