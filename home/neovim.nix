{ pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Stylix injects the colourscheme automatically before this config loads.
    # Do not set a colorscheme here; Stylix owns that.
    extraConfig = builtins.readFile ./dotfiles/neovim/init.lua;

    # Python provider — points to the system Python
    # Used for running code directly from Neovim without plugins
    extraPython3Packages = (ps: with ps; []);
  };

  # Stable Python path for g:python3_host_prog in init.vim
  home.sessionVariables = {
    NVIM_PYTHON = "${pkgs.python3}/bin/python3";
  };
}
