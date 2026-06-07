{ pkgs, ... }: {
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-pgtk;  # Wayland-native (GTK4 pure)
    extraPackages = epkgs: with epkgs; [

      # ── Evil ─────────────────────────────────────────────────────────────
      evil
      evil-collection    # evil in every buffer (magit, dired, org, elfeed…)
      evil-surround      # cs, ds, ys surround motions
      evil-commentary    # gc to comment lines
      evil-goggles       # flash on yank/delete/paste
      general            # SPC-leader keybinding framework

      # ── UI ───────────────────────────────────────────────────────────────
      which-key
      vertico            # vertical minibuffer completion
      marginalia         # annotations in completion (file size, docstrings)
      consult            # enhanced commands: consult-line, grep, recent, etc.
      orderless          # fuzzy / space-separated completion matching
      embark             # action menu on completion candidate
      embark-consult

      # ── Navigation ───────────────────────────────────────────────────────
      avy                # jump to any char/word on screen
      projectile         # project-aware find-file, grep, etc.

      # ── Git ──────────────────────────────────────────────────────────────
      magit
      diff-hl            # gutter diff indicators (±)

      # ── Org ──────────────────────────────────────────────────────────────
      org-roam           # zettelkasten backlink database
      org-roam-ui        # D3 graph view in browser
      org-ql             # query language (replaces dataview)
      org-superstar      # prettier headings (★ → ◆)
      org-modern         # cleaner tables, tags, todo keywords
      org-transclusion   # embed sections from other org files live

      # ── Citations ────────────────────────────────────────────────────────
      citar              # citation management over .bib files (includes org-cite integration)
      org-roam-bibtex    # link .bib entries to org-roam nodes

      # ── RSS + YouTube ────────────────────────────────────────────────────
      elfeed
      elfeed-org         # manage feed list in elfeed.org
      elfeed-tube        # YouTube in elfeed (plays via mpv)

      # ── Typst ────────────────────────────────────────────────────────────
      typst-ts-mode      # tree-sitter mode for .typ files + tinymist LSP
      # ox-typst         # org→Typst exporter — run: nix search nixpkgs#emacs-packages.ox-typst
      #                  # If not packaged: add via overlay or straight.el

      # ── Workspaces ───────────────────────────────────────────────────────
      perspective        # named workspaces (personal / uni)

      # ── File browsing ────────────────────────────────────────────────────
      dired-sidebar      # persistent sidebar (replaces Obsidian file tree)

      # ── PDF ──────────────────────────────────────────────────────────────
      pdf-tools          # view PDFs in Emacs

      # ── Calendar ─────────────────────────────────────────────────────────
      org-gcal           # two-way Google Calendar sync

      # ── Writing / appearance ─────────────────────────────────────────────
      mixed-pitch        # variable font for prose, mono for code blocks
      olivetti           # centered writing mode
      jinx               # fast spell checking (English + Dutch)

      # ── Code ─────────────────────────────────────────────────────────────
      treesit-auto       # auto tree-sitter grammars
      markdown-mode
      vterm              # fast terminal inside Emacs

      # ── Music ────────────────────────────────────────────────────────────
      emms               # Emacs Multimedia System (plays via mpv)
    ];
  };

  xdg.configFile."emacs/early-init.el".source = ./dotfiles/emacs/early-init.el;
  xdg.configFile."emacs/init.el".source       = ./dotfiles/emacs/init.el;
  xdg.configFile."emacs/config.org".source    = ./dotfiles/emacs/config.org;
  xdg.configFile."emacs/elfeed.org".source    = ./dotfiles/emacs/elfeed.org;
}
