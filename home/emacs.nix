{ pkgs, lib, config, ... }: {
  programs.emacs = {
    enable  = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: with epkgs; [
      evil
      evil-collection
      general
      which-key
      markdown-mode
    ];
  };

  xdg.configFile."emacs/early-init.el".source         = ./dotfiles/emacs/early-init.el;
  xdg.configFile."emacs/init.el".source               = ./dotfiles/emacs/init.el;
  xdg.configFile."emacs/themes/ukiyo-theme.el".source = ./dotfiles/emacs/ukiyo-theme.el;

  # config.org is deployed as a mutable copy on first install so it can be edited
  # without a Nix rebuild. To update the Nix source after editing the live file,
  # copy ~/.config/emacs/config.org back to home/dotfiles/emacs/config.org and commit.
  home.activation.emacsConfigOrg = lib.hm.dag.entryAfter ["writeBoundary"] ''
    dest="${config.xdg.configHome}/emacs/config.org"
    if [ ! -f "$dest" ]; then
      $DRY_RUN_CMD cp -- ${./dotfiles/emacs/config.org} "$dest"
      $DRY_RUN_CMD chmod 644 "$dest"
    fi
  '';
}
