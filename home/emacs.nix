{ pkgs, lib, config, ... }: {
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: with epkgs; [
      # ── Evil ──────────────────────────────────────────────────────────────
      evil
      evil-collection
      evil-surround        # cs, ds, ys surround operations
      evil-commentary      # gc to comment lines
      evil-goggles         # visual flash on evil operations

      # ── Leader / keybindings ──────────────────────────────────────────────
      general
      which-key

      # ── Completion stack ──────────────────────────────────────────────────
      vertico              # vertical minibuffer
      orderless            # fuzzy space-separated matching
      marginalia           # annotations in minibuffer
      consult              # enhanced find-file, grep, buffer switch
      embark               # act on minibuffer candidates
      embark-consult

      # ── Navigation ────────────────────────────────────────────────────────
      avy                  # on-screen jump by character
      projectile           # project-aware operations

      # ── Git ───────────────────────────────────────────────────────────────
      magit
      diff-hl              # gutter change indicators

      # ── Files ─────────────────────────────────────────────────────────────
      dired-sidebar        # persistent left file tree

      # ── Appearance ────────────────────────────────────────────────────────
      mixed-pitch          # variable pitch in prose, mono in code
      olivetti             # centered writing mode
      org-superstar        # prettier org heading bullets
      org-modern           # modern org rendering (tables, tags, todos)

      # ── Org ───────────────────────────────────────────────────────────────
      org-roam
      org-roam-ui          # interactive graph browser
      org-ql               # query language for org files (replaces Dataview)
      org-transclusion     # embed sections from other org files live
      org-gcal             # Google Calendar sync (needs ~/.authinfo.gpg)
      citar                # citation management against .bib files
      org-roam-bibtex      # link .bib entries to org-roam nodes

      # ── Spell check ───────────────────────────────────────────────────────
      jinx                 # fast spell check via enchant2 (en + nl)

      # ── PDF ───────────────────────────────────────────────────────────────
      pdf-tools            # view PDFs inside Emacs

      # ── RSS / YouTube ─────────────────────────────────────────────────────
      elfeed               # RSS reader
      elfeed-org           # manage feed list in an org file
      elfeed-tube          # YouTube metadata + mpv playback

      # ── Terminal ──────────────────────────────────────────────────────────
      ghostel              # libghostty-vt terminal: Kitty graphics, mouse passthrough, fast
      # vterm              # fallback: C/libvterm, no Kitty graphics, slower

      # ── Music ─────────────────────────────────────────────────────────────
      libmpdel             # MPD protocol library
      mpdel                # Emacs MPD client (hierarchical browser)

      # ── Workspaces ────────────────────────────────────────────────────────
      perspective          # named workspaces with separate buffer lists

      # ── Email ─────────────────────────────────────────────────────────────
      mu4e                 # Email client (pairs with system mu maildir indexer)

      # ── Markup / writing ──────────────────────────────────────────────────
      markdown-mode
      typst-ts-mode        # .typ files with tree-sitter + tinymist LSP
    ];
  };

  services.emacs = {
    enable = true;
  };

  # Restart daemon always (not just on crash) so closing a frame doesn't kill it permanently
  systemd.user.services.emacs = {
    Service.Restart = lib.mkForce "always";
    Service.RestartSec = "2s";
  };

  # Override the system emacs.desktop so rofi launches via the daemon
  # --no-wait: don't block the launcher process waiting for the frame to close
  # --alternate-editor=emacs: fall back to plain emacs if daemon isn't up yet
  home.file.".local/share/applications/emacs.desktop".text = ''
    [Desktop Entry]
    Name=Emacs
    GenericName=Text Editor
    Comment=Edit text
    Exec=emacsclient --no-wait --alternate-editor=emacs %F
    Icon=emacs
    Type=Application
    Terminal=false
    Categories=Development;TextEditor;
    MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
    StartupNotify=true
    StartupWMClass=Emacs
  '';

  xdg.configFile."emacs/early-init.el".source         = ./dotfiles/emacs/early-init.el;
  xdg.configFile."emacs/init.el".source               = ./dotfiles/emacs/init.el;
  xdg.configFile."emacs/themes/ukiyo-theme.el".source = ./dotfiles/emacs/ukiyo-theme.el;

  # config.org and elfeed.org are deployed as mutable copies on first install so
  # they can be edited without a Nix rebuild. To persist changes back to git,
  # copy them back to home/dotfiles/emacs/ and commit.
  home.activation.emacsConfigOrg = lib.hm.dag.entryAfter ["writeBoundary"] ''
    dest="${config.xdg.configHome}/emacs/config.org"
    if [ ! -f "$dest" ]; then
      $DRY_RUN_CMD cp -- ${./dotfiles/emacs/config.org} "$dest"
      $DRY_RUN_CMD chmod 644 "$dest"
    fi
  '';

  home.activation.emacsElfeedOrg = lib.hm.dag.entryAfter ["writeBoundary"] ''
    dest="${config.xdg.configHome}/emacs/elfeed.org"
    if [ ! -f "$dest" ]; then
      $DRY_RUN_CMD cp -- ${./dotfiles/emacs/elfeed.org} "$dest"
      $DRY_RUN_CMD chmod 644 "$dest"
    fi
  '';
}
