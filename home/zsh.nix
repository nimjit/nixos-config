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

      # Emacs client — opens a frame in the running daemon; falls back to plain emacs if daemon is down
      e   = "emacsclient -c --alternate-editor=emacs";

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
      # Keep lpass agent alive for the full login session (needed for mbsync timer)
      LPASS_AGENT_TIMEOUT = "0";
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
        nh os switch /etc/nixos -H desktop -- --impure || return 1
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

      # nixdiff: compare two NixOS generations to see what packages changed
      # Usage: nixdiff        → compares last two generations automatically
      #        nixdiff 133 134 → compares specific generations
      nixdiff() {
        if [[ $# -eq 0 ]]; then
          local -a profiles=(/nix/var/nix/profiles/system-*-link(nN))
          if (( ''${#profiles} < 2 )); then
            echo "Need at least 2 generations"
            return 1
          fi
          nvd diff "''${profiles[-2]}" "''${profiles[-1]}"
        else
          nvd diff /nix/var/nix/profiles/system-$1-link /nix/var/nix/profiles/system-$2-link
        fi
      }

      # Workflow launchers
      uni-work()   { nvim -c WorkflowUni; }
      uni-code()   { nvim -c WorkflowCode; }
      vault-work() { nvim -c WorkflowVault; }
      nixos-work() { nvim -c WorkflowNixos; }

      # Terminal web browser (w3m)
      # wb           → opens WB_HOME (localhost:8080 by default)
      # wb URL       → opens specific URL
      # Inside neovim terminal ($NVIM is set): opens in a bottom split
      # Navigation: arrows/Enter=follow link, U=enter URL, B=back, q=quit
      WB_HOME="http://localhost:8080"
      wb() {
        local url="''${1:-$WB_HOME}"
        if [[ -n "$NVIM" ]]; then
          nvim --server "$NVIM" --remote-send ":botright split | terminal w3m $(printf '%q' "$url")<CR>"
        else
          w3m "$url"
        fi
      }

      # nchat and rmpc run in persistent dtach sessions.
      # dtach -A: attach if session exists, create+attach if not.
      # Closing the kitty tab detaches; calling again re-attaches.
      messages() {
        printf '0' > /tmp/nchat-unread
        # Only focus an existing messages tab if it is in the current kitty OS window.
        # focus-tab alone returns 0 even for background windows (Wayland can't raise those).
        if kitten @ ls 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
for w in d:
    if w.get('is_focused'):
        if any(t.get('title') == 'messages' for t in w.get('tabs', [])):
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
          kitten @ focus-tab --match "title:^messages$" 2>/dev/null
          return
        fi
        # No messages tab in current window: attach to the service's dtach session
        kitten @ launch --type=tab --tab-title messages -- dtach -a /tmp/nchat-dtach &>/dev/null || \
          dtach -a /tmp/nchat-dtach
      }

      projects() {
        local persist_todo="$HOME/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/Misc/ToDo.md"
        [[ -f "$persist_todo" ]] || { echo "No projects file found."; return; }
        local in_proj=0
        typeset -a proj_list=()
        while IFS= read -r line; do
          [[ "$line" == "## Projects" ]] && { in_proj=1; continue; }
          [[ "$line" =~ ^## ]] && (( in_proj )) && break
          if (( in_proj )) && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            proj_list+=("''${line#*- }")
          fi
        done < "$persist_todo"
        (( ''${#proj_list[@]} == 0 )) && { echo "No projects."; return; }
        local today_idx=$(( ($(date +%j) - 1) % ''${#proj_list[@]} ))
        echo "Projects"
        for (( i=1; i<=''${#proj_list[@]}; i++ )); do
          if (( i - 1 == today_idx )); then
            printf "  %d  %s  ← today\n" "$i" "''${proj_list[$i]}"
          else
            printf "  %d  %s\n" "$i" "''${proj_list[$i]}"
          fi
        done
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

      email() {
        if kitten @ ls 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
for w in d:
    if w.get('is_focused'):
        if any(t.get('title') == 'email' for t in w.get('tabs', [])):
            sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
          kitten @ focus-tab --match "title:^email$" 2>/dev/null
          return
        fi
        kitten @ launch --type=tab --tab-title email -- neomutt &>/dev/null || neomutt
      }

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
          # ToDo: daily note + persistent file, shown under one header
          local found_any=0
          if [[ -f "$daily" ]]; then
            local in_todo=0
            while IFS= read -r line; do
              [[ "$line" == "## ToDo" ]] && { in_todo=1; continue; }
              [[ "$line" =~ ^## ]] && (( in_todo )) && break
              if (( in_todo )) && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                (( found_any == 0 )) && { right_col+=(""); right_col+=("ToDo"); found_any=1; }
                right_col+=("  · ''${line#*- }")
              fi
            done < "$daily"
          fi
          local persist_todo="$HOME/Documents/BACKUP/Obsidian/Renaissance_Vault_Structure/Renaissance_Vault_Structure/Misc/ToDo.md"
          if [[ -f "$persist_todo" ]]; then
            local in_ptodo=0
            while IFS= read -r line; do
              [[ "$line" == "## ToDo" ]] && { in_ptodo=1; continue; }
              [[ "$line" =~ ^## ]] && (( in_ptodo )) && break
              if (( in_ptodo )) && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                (( found_any == 0 )) && { right_col+=(""); right_col+=("ToDo"); found_any=1; }
                right_col+=("  · ''${line#*- }")
              fi
            done < "$persist_todo"
          fi

          # Project rotation: one project per day from ## Projects in ToDo.md
          if [[ -f "$persist_todo" ]]; then
            local in_proj=0
            typeset -a proj_rot=()
            while IFS= read -r line; do
              [[ "$line" == "## Projects" ]] && { in_proj=1; continue; }
              [[ "$line" =~ ^## ]] && (( in_proj )) && break
              if (( in_proj )) && [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
                proj_rot+=("''${line#*- }")
              fi
            done < "$persist_todo"
            if (( ''${#proj_rot[@]} > 0 )); then
              local proj_idx=$(( ($(date +%j) - 1) % ''${#proj_rot[@]} ))
              right_col+=("")
              right_col+=("Project today")
              right_col+=("  · ''${proj_rot[$(( proj_idx + 1 ))]}")
            fi
          fi

          # Mail: sender names from From: headers
          local mail_senders
          mail_senders=$(python3 - <<'PYEOF'
import os, glob
from email.header import decode_header

def decode_from(raw):
    parts = decode_header(raw)
    name = ""
    for b, enc in parts:
        if isinstance(b, bytes):
            name += b.decode(enc or "utf-8", errors="replace")
        else:
            name += b
    name = name.split("<")[0].strip().strip('"')
    return name or raw.split("<")[0].strip()

files = glob.glob(os.path.expanduser("~/Mail/*/INBOX/new/*"))
senders = []
for f in sorted(files, key=os.path.getmtime, reverse=True)[:4]:
    try:
        for line in open(f, errors="replace"):
            if line.startswith("From:"):
                senders.append(decode_from(line[5:].strip()))
                break
    except Exception:
        pass
for s in senders:
    print(s)
PYEOF
)
          if [[ -n $mail_senders ]]; then
            local mail_count
            mail_count=$(find "$HOME/Mail" -path "*/INBOX/new/*" -type f 2>/dev/null | wc -l)
            right_col+=("")
            right_col+=("Mail  ($mail_count)")
            while IFS= read -r sender; do
              right_col+=("  $sender")
            done <<< "$mail_senders"
          fi

          # nchat unread count
          local nchat_unread
          nchat_unread=$(cat /tmp/nchat-unread 2>/dev/null | tr -d '[:space:]')
          if [[ -n $nchat_unread && $nchat_unread -gt 0 ]]; then
            right_col+=("")
            right_col+=("Messages  ($nchat_unread)")
          fi

          # Render side by side
          local n_max=$(( ''${#left_col[@]} > ''${#right_col[@]} ? ''${#left_col[@]} : ''${#right_col[@]} ))
          for (( i=1; i<=n_max; i++ )); do
            printf "  %-44s  │  %s\n" "''${left_col[$i]:-}" "''${right_col[$i]:-}"
          done

          echo ""
          printf '  %stoday  vault-work  uni-work  messages  email  music  cal%s\n' "$DIM" "$RESET"
          echo ""
        }
        _greeting
      fi
    '';
    dotDir = "${config.xdg.configHome}/zsh";
  };

  # Starship prompt — Stylix themes it automatically.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      python.disabled  = true;
      nodejs.disabled  = true;
      rust.disabled    = true;
      package.disabled = true;
    };
  };
}
