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
      cal     = "vdirsyncer sync > /dev/null 2>&1 && ikhal";

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

      # nchat runs in a persistent dtach session (managed by systemd).
      # Closing the kitty tab detaches it; messages() re-attaches.
      messages() {
        local _attach='dtach -a /tmp/nchat-dtach 2>/dev/null || dtach -n /tmp/nchat-dtach nchat'
        kitty @ focus-tab --match title:messages 2>/dev/null || \
          kitty @ launch --type=tab --tab-title messages sh -c "$_attach" 2>/dev/null || \
          sh -c "$_attach"
      }

      # Append a quick thought to today's personal vault daily note without opening an editor.
      cap() {
        local text="$*"
        local date=$(date +%Y-%m-%d)
        local daily=~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/Dailies/$date.md
        if [ ! -f "$daily" ]; then
          printf -- "---\ndate: %s\n---\n\n## Inbox\n" "$date" > "$daily"
        fi
        printf -- "\n- %s" "$text" >> "$daily"
        echo "→ $date"
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
        _greeting() {
          local GOLD DIM RESET cols
          GOLD=$'\033[33m'
          DIM=$'\033[2m'
          RESET=$'\033[0m'
          cols=$(tput cols 2>/dev/null || echo 80)

          _center() {
            local text="$1" plain len pad
            plain=$(printf '%s' "$text" | sed 's/\x1B\[[0-9;]*m//g')
            len=$(printf '%s' "$plain" | wc -m)
            pad=$(( (cols - len) / 2 ))
            (( pad < 0 )) && pad=0
            printf '%*s%s\n' "$pad" "" "$text"
          }

          local date_str weather quote today_ev tmrw_ev
          date_str=$(date "+%A %-d %B %Y  ·  %H:%M")

          local wttr=/tmp/wttr_leiden_cache
          if [[ ! -f $wttr ]] || [[ -n $(find "$wttr" -mmin +30 2>/dev/null) ]]; then
            curl -s --max-time 2 "wttr.in/Leiden?format=%c+%t" >$wttr 2>/dev/null || printf '  ' >$wttr
          fi
          weather=$(<$wttr)

          quote=$(fortune -s 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-55)

          today_ev=$(khal list today today --format "{start-time} {title}" 2>/dev/null | grep -v '^$' | head -3)
          tmrw_ev=$(khal list tomorrow tomorrow --format "{start-time} {title}" 2>/dev/null | grep -v '^$' | head -2)

          echo ""
          _center "$GOLD$date_str$RESET"
          echo ""
          _center "$DIM$weather   ·   $quote$RESET"
          echo ""

          if [[ -n $today_ev ]]; then
            printf '  %sToday%s\n' "$GOLD" "$RESET"
            while IFS= read -r line; do printf '    %s\n' "$line"; done <<< "$today_ev"
          else
            printf '  %sToday     —%s\n' "$DIM" "$RESET"
          fi

          if [[ -n $tmrw_ev ]]; then
            printf '  %sTomorrow%s\n' "$GOLD" "$RESET"
            while IFS= read -r line; do printf '    %s\n' "$line"; done <<< "$tmrw_ev"
          else
            printf '  %sTomorrow  —%s\n' "$DIM" "$RESET"
          fi

          echo ""
          printf '  %suni-work  vault-work  nixos-work  today  messages  music  cal%s\n' "$DIM" "$RESET"
          echo ""
        }
        _greeting
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
