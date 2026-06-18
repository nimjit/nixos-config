{ pkgs, ... }: {
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
}
