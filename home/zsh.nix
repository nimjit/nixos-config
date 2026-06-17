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
      ignoreAllDups = true;
      share = true;
    };

    shellAliases = {
      # NixOS shortcuts
      update   = "cd /etc/nixos && git pull && nh os switch /etc/nixos -H desktop";
      gc       = "sudo nix-collect-garbage --delete-older-than 30d";
      gens     = "sudo nixos-rebuild list-generations";

      # Common — eza replaces ls; bat replaces cat
      ls  = "eza";
      ll  = "eza -la --git";
      la  = "eza -a";
      lt  = "eza -T";
      cat = "bat -p";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Python shortcuts
      py  = "python3";
      ipy = "ipython";

      # Kitten shortcuts
      ssh = "kitten ssh";

      # YouTube TUI
      yt  = "~/.local/bin/yt-feed";

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
      # bat as man pager — colored, searchable man pages
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      # matplotlib renders plots inline in the terminal (no Qt window; use plt.savefig() to save)
      MPLBACKEND = "kitty";
    };

    initContent = ''
      # direnv hook (activates .envrc in project folders)
      eval "$(direnv hook zsh)"

      # zoxide — smarter cd; --cmd cd replaces cd directly, no new verb to learn
      eval "$(zoxide init zsh --cmd cd)"

      # rebuild: switch + save git hash for nix status + append to generations.md
      rebuild() {
        nh os switch /etc/nixos -H desktop || return 1
        git -C /etc/nixos rev-parse HEAD > ~/.config/nixos-last-build-hash
        local gen=$(nixos-rebuild list-generations 2>/dev/null | awk '/True/{print $1}')
        local dt=$(date "+%Y-%m-%d  %H:%M")
        local hash=$(git -C /etc/nixos rev-parse --short HEAD 2>/dev/null)
        local prev=$(tail -1 /etc/nixos/generations.md | awk -F'|' '{print $4}' | tr -d ' ')
        local desc
        if [[ "$hash" == "$prev" ]]; then
          desc="(same commit, re-run)"
        else
          desc=$(git -C /etc/nixos log -1 --format="%s" 2>/dev/null)
        fi
        printf "| %3d | %s | %-7s | %s |\n" "$gen" "$dt" "$hash" "$desc" \
          >> /etc/nixos/generations.md
      }

      # nix status: hash-based rebuild check; all other nix subcommands pass through
      nix() {
        if [[ "$1" == "status" ]]; then
          local last=$(cat ~/.config/nixos-last-build-hash 2>/dev/null)
          local head=$(git -C /etc/nixos rev-parse HEAD 2>/dev/null)
          local dirty=$(git -C /etc/nixos status --short -- '*.nix' 'flake.*')
          [[ -n "$dirty" ]] && printf "Uncommitted changes:\n%s\n\n" "$dirty"
          if [[ -z "$last" ]]; then
            echo "No build record. Run rebuild once to start tracking."
          elif [[ "$last" == "$head" ]]; then
            echo "Up to date (last build = HEAD)."
          else
            local log=$(git -C /etc/nixos log --oneline "$last..$head" \
              -- home/ modules/ hosts/ flake.nix flake.lock 2>/dev/null)
            if [[ -n "$log" ]]; then
              printf "Committed but not built:\n%s\n" "$log"
            else
              echo "Up to date (no .nix changes since last build)."
            fi
          fi
        else
          command nix "$@"
        fi
      }

      # Workflow launchers
      uni-work()   { nvim -c WorkflowUni; }
      uni-code()   { nvim -c WorkflowCode; }
      vault-work() { nvim -c WorkflowVault; }
      nixos-work() { nvim -c WorkflowNixos; }

      # nchat and rmpc run in persistent dtach sessions.
      # dtach -A: attach if session exists, create+attach if not.
      # Closing the kitty tab detaches; calling again re-attaches.
      messages() {
        # Exact regex match — focus existing tab if open
        if kitten @ focus-tab --match "title:^messages$" 2>/dev/null; then
          return 0
        fi
        # nchat running but tab gone — attach to existing dtach session in new tab
        if pgrep -x nchat >/dev/null; then
          kitten @ launch --type=tab --tab-title messages dtach -A /tmp/nchat-dtach nchat 2>/dev/null
          return 0
        fi
        # nchat not running — start fresh; fall back to current terminal if outside kitty
        kitten @ launch --type=tab --tab-title messages dtach -A /tmp/nchat-dtach nchat 2>/dev/null || \
          dtach -A /tmp/nchat-dtach nchat
      }

      # Append a quick thought to today's personal vault daily note without opening an editor.
      cap() {
        local text="$*"
        local date=$(date +%Y-%m-%d)
        local vault=~/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure
        local daily="$vault/Dailies/$date.md"
        local template="$vault/Templates/Daily Note.md"
        if [ ! -f "$daily" ]; then
          if [ -f "$template" ]; then
            sed "s/{{date}}/$date/g" "$template" > "$daily"
          else
            printf -- "# %s\n\n## Schedule\n\n## ToDo\n\n## Inbox\n" "$date" > "$daily"
          fi
        fi
        printf -- "\n- %s" "$text" >> "$daily"
        echo "→ $date"
      }

      music() { rmpc; }

      # Greeting: only in interactive top-level shells, never inside neovim :terminal
      if [[ -o interactive && -z "$NVIM" && $SHLVL -eq 1 ]]; then

        _deadlines() {
          local uni_dir="$HOME/Documents/BACKUP/Uni/Obsidian/Uni"
          local today_ts=$(date +%s)
          local results=()
          local dt ev_ts diff title class completed_val grade_val

          # Exams / deadlines
          for f in "$uni_dir/Deadines"/*.md; do
            [[ -f "$f" ]] || continue
            completed_val=$(grep "^completed:" "$f" | head -1 | sed 's/^completed:[[:space:]]*//' | tr -d '"')
            [[ -z "$completed_val" || "''${completed_val:l}" == "false" ]] || continue
            dt=$(grep "^date:" "$f" | head -1 | awk '{print $2}')
            [[ -z "$dt" ]] && continue
            [[ "$dt" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]] && dt="''${dt:6:4}-''${dt:3:2}-''${dt:0:2}"
            ev_ts=$(date -d "$dt" +%s 2>/dev/null) || continue
            diff=$(( (ev_ts - today_ts) / 86400 ))
            [[ $diff -lt 0 || $diff -gt 21 ]] && continue
            class=$(grep "^class:" "$f" | head -1 | sed 's/^class:[[:space:]]*//')
            title=$(grep "^title:" "$f" | head -1 | sed 's/^title:[[:space:]]*//')
            results+=("$diff|$dt|$class|$title")
          done

          # Assignments
          for f in "$uni_dir/Assignments"/*.md; do
            [[ -f "$f" ]] || continue
            grade_val=$(grep "^grade:" "$f" | head -1 | sed 's/^grade:[[:space:]]*//')
            [[ -n "$grade_val" ]] && continue
            dt=$(grep "^deadline:" "$f" | head -1 | awk '{print $2}')
            [[ -z "$dt" ]] && continue
            [[ "$dt" =~ ^[0-9]{2}-[0-9]{2}-[0-9]{4}$ ]] && dt="''${dt:6:4}-''${dt:3:2}-''${dt:0:2}"
            ev_ts=$(date -d "$dt" +%s 2>/dev/null) || continue
            diff=$(( (ev_ts - today_ts) / 86400 ))
            [[ $diff -lt 0 || $diff -gt 21 ]] && continue
            class=$(grep "^class:" "$f" | head -1 | sed 's/^class:[[:space:]]*//')
            title=$(grep "^type:" "$f" | head -1 | sed 's/^type:[[:space:]]*//')
            results+=("$diff|$dt|$class|$title")
          done

          (( ''${#results[@]} > 0 )) || return
          printf '%s\n' "''${results[@]}" | sort -t'|' -k1 -n | while IFS='|' read -r diff dt cls ttl; do
            [[ -n "$dt" ]] || continue
            mon=$(date -d "$dt" "+%-d %b" 2>/dev/null || echo "$dt")
            printf "in %2dd  (%s)  %s%s\n" "$diff" "$mon" "''${cls:+$cls — }" "$ttl"
          done
        }

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
          date_str=$(date "+%A %-d %B %Y")

          local wttr=/tmp/wttr_leiden_cache
          if [[ ! -f $wttr ]] || [[ -n $(find "$wttr" -mmin +30 2>/dev/null) ]]; then
            curl -s --max-time 2 "wttr.in/Leiden?format=%c+%t" >$wttr 2>/dev/null || printf '  ' >$wttr
          fi
          weather=$(<$wttr)

          quote=$(fortune -s 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g' | cut -c1-55)

          today_ev=$(khal list today today --format "{start-time} {title}" 2>/dev/null | grep -v '^$')
          tmrw_ev=$(khal list tomorrow tomorrow --format "{start-time} {title}" 2>/dev/null | grep -v '^$')

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
          echo ""
          if [[ -n $tmrw_ev ]]; then
            printf '  %sTomorrow%s\n' "$GOLD" "$RESET"
            while IFS= read -r line; do printf '    %s\n' "$line"; done <<< "$tmrw_ev"
          else
            printf '  %sTomorrow  —%s\n' "$DIM" "$RESET"
          fi
          echo ""

          local daily="$HOME/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/Dailies/$(date +%Y-%m-%d).md"

          # Collect timed events from khal + ## Schedule in daily note: "HH:MM|Title"
          typeset -a all_events=()
          while IFS= read -r line; do
            [[ "$line" =~ ^[0-9]{2}:[0-9]{2} ]] || continue
            all_events+=("''${line:0:5}|''${line:6}")
          done < <(khal list today today --format "{start-time} {title}" 2>/dev/null)
          if [[ -f "$daily" ]]; then
            local in_sched=0
            while IFS= read -r line; do
              [[ "$line" == "## Schedule" ]] && { in_sched=1; continue; }
              [[ "$line" =~ ^## ]] && (( in_sched )) && { in_sched=0; continue; }
              (( in_sched )) && [[ "$line" =~ ^[0-9]{2}:[0-9]{2} ]] && all_events+=("''${line:0:5}|''${line:6}")
            done < "$daily"
          fi
          # Sort by time
          typeset -a sorted_events=()
          while IFS= read -r line; do sorted_events+=("$line"); done < <(printf '%s\n' "''${all_events[@]}" | sort)
          all_events=("''${sorted_events[@]}")

          # Build left column (timetable 09–22)
          typeset -a left_col=()
          left_col+=("        │ Schedule")
          local hh
          for hour in {9..22}; do
            hh=$(printf "%02d" $hour)
            typeset -a hour_evs=()
            for ev in "''${all_events[@]}"; do
              [[ "''${ev%%|*}" == "$hh:"* ]] && hour_evs+=("''${ev#*|}")
            done
            if (( ''${#hour_evs[@]} == 0 )); then
              left_col+=("  $hh:00 │")
            else
              left_col+=("  $hh:00 │ ''${hour_evs[1]:0:34}")
              for (( j=2; j<=''${#hour_evs[@]}; j++ )); do
                left_col+=("        │ ''${hour_evs[$j]:0:34}")
              done
            fi
          done

          # Build right column
          typeset -a right_col=()
          right_col+=("Dailies")
          right_col+=("  □ Brush teeth")
          right_col+=("  □ Eat vegetables")
          right_col+=("  □ Put on deodorant")
          right_col+=("  □ Write in journal")
          right_col+=("")
          right_col+=("Deadlines")
          while IFS= read -r line; do
            [[ -n "$line" ]] && right_col+=("  $line")
          done < <(_deadlines)
          # ToDo from ## ToDo section in daily note
          if [[ -f "$daily" ]]; then
            local in_todo=0 found_any=0
            while IFS= read -r line; do
              [[ "$line" == "## ToDo" ]] && { in_todo=1; continue; }
              [[ "$line" =~ ^## ]] && (( in_todo )) && break
              if (( in_todo )) && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                (( found_any == 0 )) && { right_col+=(""); right_col+=("ToDo"); found_any=1; }
                right_col+=("  · ''${line#*- }")
              fi
            done < "$daily"
          fi

          # Render side by side
          local n_max=$(( ''${#left_col[@]} > ''${#right_col[@]} ? ''${#left_col[@]} : ''${#right_col[@]} ))
          for (( i=1; i<=n_max; i++ )); do
            printf "  %-44s  │  %s\n" "''${left_col[$i]:-}" "''${right_col[$i]:-}"
          done

          echo ""
          printf '  %stoday  vault-work  uni-work  messages  music  cal%s\n' "$DIM" "$RESET"
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
