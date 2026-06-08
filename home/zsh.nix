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
      vault   = "yazi ~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure";
      uni     = "yazi ~/Documents/BACKUP/Uni/Obsidian/Uni";
      ricing  = "yazi ~/Documents/BACKUP/Ricing";
      misc    = "yazi ~/Documents/BACKUP/Misc";
      books   = "yazi ~/Documents/BACKUP/Books";

      # Calendar — syncs (stdout suppressed, errors shown) then opens TUI
      cal     = "calcurse-caldav > /dev/null 2>&1 && calcurse";

      # Daily note shortcut
      today   = "nvim -c DailyNote";

      # Use Yazi instead of plain file browsing
      # (the 'y' wrapper is set in yazi.nix)

      # Home-manager does not configure root, so nvim in root does not apply init.lua
      # this alias makes any nvim run in sudo, whilst perserving the environment:
      "sudo nvim" = "sudo -E nvim";
    };

    sessionVariables = {
      # lpass --clip uses wl-copy on Wayland
      LPASS_CLIPBOARD_COMMAND = "wl-copy";
    };

    initContent = ''
      # direnv hook (activates .envrc in project folders)
      eval "$(direnv hook zsh)"

      # Workflow launchers
      uni-work()   { nvim -c WorkflowUni; }
      uni-code()   { nvim -c WorkflowCode; }
      vault-work() { nvim -c WorkflowVault; }
      nixos-work() { nvim -c WorkflowNixos; }

      # nchat in a dedicated kitty tab; falls back to current terminal if kitty remote control unavailable
      messages() {
        kitty @ focus-tab --match title:nchat 2>/dev/null || \
          kitty @ launch --type=tab --tab-title nchat nchat 2>/dev/null || \
          nchat
      }

      # rmpc in a dedicated kitty tab; auto-queues full library if idle.
      # Falls back to current terminal if kitty remote control unavailable.
      music() {
        mpc playlist | grep -q . || (mpc add / && mpc shuffle && mpc play)
        kitty @ focus-tab --match title:music 2>/dev/null || \
          kitty @ launch --type=tab --tab-title music rmpc 2>/dev/null || \
          rmpc
      }

      # Greeting: only in interactive top-level shells, never inside neovim :terminal
      if [[ -o interactive && -z "$NVIM" && $SHLVL -eq 1 ]]; then
        echo ""
        echo " Go to:"
        echo "  nixos   → /etc/nixos"
        echo "  backup  → ~/Documents/BACKUP"
        echo "  vault   → Renaissance vault"
        echo "  uni     → Uni vault"
        echo "  books   → ~/Documents/BACKUP/Books"
        echo ""
        echo "  Workflows:"
        echo "  uni-work   →  Uni dashboard"
        echo "  uni-code   →  Current coding project"
        echo "  vault-work →  Personal vault + Claude"
        echo "  nixos-work →  NixOS config + Claude"
        echo "  today      →  Today's daily note"
        echo "  messages   →  WhatsApp (nchat)"
        echo "  music      →  Music player (rmpc)"
        echo "  cal        →  Calendar (calcurse)"
        echo ""
      fi
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
