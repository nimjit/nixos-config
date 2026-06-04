{ pkgs, config, ... }: {

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    shellAliases = {
      # NixOS shortcuts
      rebuild  = "nh os switch /etc/nixos -H desktop";
      update   = "cd /etc/nixos && git pull && nh os switch /etc/nixos -H desktop";
      gc       = "sudo nix-collect-garbage --delete-older-than 30d";
      gens     = "sudo nixos-rebuild list-generations";

      # Common
      ll  = "ls -lah";
      la  = "ls -A";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Navigation
      nixos   = "yazi /etc/nixos";
      backup  = "yazi ~/Documents/BACKUP";
      vault   = "yazi ~/Documents/BACKUP/Obsidian/Rennaissance_Vault_Structure";
      uni     = "yazi ~/Documents/BACKUP/Uni";
      ricing  = "yazi ~/Documents/BACKUP/Ricing";
      misc    = "yazi ~/Documents/BACKUP/Misc";
      books   = "yazi ~/Documents/BACKUP/Books";

      # Use Yazi instead of plain file browsing
      # (the 'y' wrapper is set in yazi.nix)

      # Home-manager does not configure root, so nvim in root does not apply init.lua
      # this alias makes any nvim run in sudo, whilst perserving the environment:
      "sudo nvim" = "sudo -E nvim";
    };

    initContent = ''
      # direnv hook (activates .envrc in project folders)
      eval "$(direnv hook zsh)"

      # Show current nixos generation in prompt (optional)
      # Uncomment if you want it:
      # NIXGEN=$(nixos-rebuild list-generations 2>/dev/null | tail -1 | awk '{print $1}')
    '';
    dotDir = "${config.xdg.configHome}/zsh";
  };

  # Starship prompt — clean, fast, shows git status, python env, etc.
  # Stylix themes it automatically.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
