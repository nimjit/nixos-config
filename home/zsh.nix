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

      # nchat in a dedicated kitty tab; falls back to current terminal if kitty remote control unavailable
      messages() {
        kitty @ focus-tab --match title:nchat 2>/dev/null || \
          kitty @ launch --type=tab --tab-title nchat nchat 2>/dev/null || \
          nchat
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
          local GOLD=$'\033[33m' DIM=$'\033[2m' RESET=$'\033[0m'
          local cols=${COLUMNS:-80}

          _center() {
            local text="$1" len pad
            # strip ANSI codes to measure visible length
            len=${#${text//$'\033['[0-9]*m/}}
            pad=$(( (cols - len) / 2 ))
            [[ $pad -lt 0 ]] && pad=0
            printf "%*s%s\n" "$pad" "" "$text"
          }

          # Date
          local date_str=$(date "+%A %-d %B %Y  ·  %H:%M")

          # Weather (cached 30 min)
          local wttr=/tmp/wttr_leiden_cache
          if [[ ! -f $wttr ]] || [[ -n $(find "$wttr" -mmin +30 2>/dev/null) ]]; then
            curl -s --max-time 2 "wttr.in/Leiden?format=%c+%t" >$wttr 2>/dev/null || printf "  " >$wttr
          fi
          local weather=$(<$wttr)

          # Quote
          local quote=$(fortune -s 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-55)

          # khal events
          local today_ev=$(khal list today today --format "{start-time} {title}" 2>/dev/null | grep -v '^$' | head -3)
          local tmrw_ev=$(khal list tomorrow tomorrow --format "{start-time} {title}" 2>/dev/null | grep -v '^$' | head -2)

          echo ""
          _center "${GOLD}${date_str}${RESET}"
          echo ""
          _center "${DIM}${weather}   ·   ${quote}${RESET}"
          echo ""

          if [[ -n $today_ev ]]; then
            printf "  ${GOLD}Today${RESET}\n"
            while IFS= read -r line; do printf "    %s\n" "$line"; done <<< "$today_ev"
          else
            printf "  ${DIM}Today     —${RESET}\n"
          fi

          if [[ -n $tmrw_ev ]]; then
            printf "  ${GOLD}Tomorrow${RESET}\n"
            while IFS= read -r line; do printf "    %s\n" "$line"; done <<< "$tmrw_ev"
          else
            printf "  ${DIM}Tomorrow  —${RESET}\n"
          fi

          echo ""
          printf "  ${DIM}uni-work  vault-work  nixos-work  today  messages  music  cal${RESET}\n"
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
