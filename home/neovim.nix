{ pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Stylix neovim target is disabled (stylix.targets.neovim.enable = false in stylix.nix)
    # so mini.base16 no longer runs. The hand-crafted Ukiyo.lua is the sole colorscheme.
    initLua = builtins.readFile ./dotfiles/neovim/init.lua;

    plugins = with pkgs.vimPlugins; [
      image-nvim   # inline image rendering via kitty graphics protocol (used for typst)
    ];

    # Python provider — points to the system Python
    # Used for running code directly from Neovim without plugins
    extraPython3Packages = (ps: with ps; []);
  };

  # Lua modules available via require() in neovim
  xdg.configFile."nvim/lua/dashboard.lua".source = ./dotfiles/neovim/lua/dashboard.lua;

  # Hand-crafted Ukiyo colorscheme — loaded by `colorscheme Ukiyo` in init.lua
  xdg.configFile."nvim/colors/Ukiyo.lua".source = ./dotfiles/neovim/colors/Ukiyo.lua;

  # Weight chart script — called by dashboard.lua after opening vault or logging weight
  home.file.".local/bin/plot-weights" = {
    source = ./dotfiles/plot-weights.py;
    executable = true;
  };

  # Stable Python path for g:python3_host_prog in init.vim
  home.sessionVariables = {
    NVIM_PYTHON = "${pkgs.python3}/bin/python3";
  };
}
