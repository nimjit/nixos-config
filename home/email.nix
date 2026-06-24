{ config, pkgs, ... }:

# ─────────────────────────────────────────────────────────────────────────────
# ~/.config/nixos-secrets.nix must contain:
#
#   {
#     gmailAddress            = "tidemanus@gmail.com";
#     gmail2Address        = "thijmen.nouwens@gmail.com";
#     nouwensLindemansAddress = "thijmen@nouwens-lindemans.nl";
#   }
#
# One-time lpass setup per account:
#   lpass add 'Gmail App Password neomutt'    ← tidemanus@gmail.com
#   lpass add 'Gmail2 App Password neomutt'   ← thijmen.nouwens@gmail.com
#   lpass add 'nouwens-lindemans.nl'           ← thijmen@nouwens-lindemans.nl
#
# Rebuild must use --impure (already set in the rebuild alias).
# ─────────────────────────────────────────────────────────────────────────────

let
  s       = import /home/thijmen/.config/nixos-secrets.nix;
  maildir = "${config.home.homeDirectory}/Mail";
in {

  # ── Address book ────────────────────────────────────────────────────────────

  home.packages = with pkgs; [ abook ];

  # ── Accounts ────────────────────────────────────────────────────────────────

  accounts.email = {
    maildirBasePath = maildir;

    # ── Gmail (tidemanus) ────────────────────────────────────────────────────
    accounts.Gmail = {
      address  = s.gmailAddress;
      userName = s.gmailAddress;
      realName = "Thijmen Nouwens";
      primary  = true;

      # Gmail IMAP uses Dutch folder names (matches the account's UI language).
      # Verify with: mbsync -c /tmp/test.conf -l Gmail  (Patterns *)
      folders = {
        inbox  = "INBOX";
        sent   = "[Gmail]/Verzonden berichten";
        drafts = "[Gmail]/Concepten";
        trash  = "[Gmail]/Prullenbak";
      };

      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 465;
               tls = { enable = true; useStartTls = false; }; };

      passwordCommand = "lpass show --password 'Gmail App Password neomutt'";

      mbsync = {
        enable  = true;
        create  = "maildir";
        expunge = "both";
        patterns = [ "INBOX" "[Gmail]/Verzonden berichten" "[Gmail]/Concepten" "[Gmail]/Prullenbak" ];
      };

      msmtp.enable = true;
      neomutt = {
        enable         = true;
        extraMailboxes = [ "[Gmail]/Verzonden berichten" "[Gmail]/Concepten" "[Gmail]/Prullenbak" ];
      };
    };

    # ── Gmail Professional (thijmen.nouwens) ────────────────────────────────
    accounts.GmailProf = {
      address  = s.gmail2Address;
      userName = s.gmail2Address;
      realName = "Thijmen Nouwens";

      # If this account's language is English the folder names differ:
      # Sent Mail / Drafts / Trash instead of Dutch names.
      # Verify with: mbsync -c /tmp/test.conf -l GmailProf  (Patterns *)
      folders = {
        inbox  = "INBOX";
        sent   = "[Gmail]/Verzonden berichten";
        drafts = "[Gmail]/Concepten";
        trash  = "[Gmail]/Prullenbak";
      };

      imap = { host = "imap.gmail.com"; port = 993; tls.enable = true; };
      smtp = { host = "smtp.gmail.com"; port = 465;
               tls = { enable = true; useStartTls = false; }; };

      passwordCommand = "lpass show --password 'Gmail2 App Password neomutt'";

      mbsync = {
        enable  = true;
        create  = "maildir";
        expunge = "both";
        patterns = [ "INBOX" "[Gmail]/Verzonden berichten" "[Gmail]/Concepten" "[Gmail]/Prullenbak" ];
      };

      msmtp.enable = true;
      neomutt = {
        enable         = true;
        extraMailboxes = [ "[Gmail]/Verzonden berichten" "[Gmail]/Concepten" "[Gmail]/Prullenbak" ];
      };
    };

    # ── Nouwens-Lindemans ────────────────────────────────────────────────────
    accounts.NouwensLindemans = {
      address  = s.nouwensLindemansAddress;
      userName = s.nouwensLindemansAddress;
      realName = "Thijmen Nouwens";

      # VERIFY: check the correct mail server with your provider.
      # Try: mbsync -c /tmp/test.conf -l NouwensLindemans  (Patterns *)
      folders = {
        inbox  = "INBOX";
        sent   = "Sent";
        drafts = "Drafts";
        trash  = "Trash";
      };

      # Cert is issued for vserver04.een2drie.nl (the hosting provider's server name).
      # Using that hostname makes TLS verification pass; the MX still points here.
      imap = { host = "vserver04.een2drie.nl"; port = 993; tls.enable = true; };
      smtp = { host = "vserver04.een2drie.nl"; port = 465;
               tls = { enable = true; useStartTls = false; }; };

      passwordCommand = "lpass show --password 'nouwens-lindemans.nl'";

      mbsync = {
        enable  = true;
        create  = "maildir";
        expunge = "both";
        patterns = [ "INBOX" "Sent" "Drafts" "Trash" ];
      };

      msmtp.enable = true;
      neomutt = {
        enable         = true;
        extraMailboxes = [ "Sent" "Drafts" "Trash" ];
      };
    };
  };

  # ── mbsync — IMAP → local maildir sync ──────────────────────────────────────

  programs.mbsync.enable = true;

  services.mbsync = {
    enable    = true;
    frequency = "*:0/5";  # sync every 5 minutes
    postExec  = let
      script = pkgs.writeShellScript "mbsync-notify" ''
        # First run after boot: seed the count file without notifying.
        count_file=/tmp/neomutt-mail-count
        if [[ -f $count_file ]]; then
          before=$(cat "$count_file")
          after=$(find "$HOME/Mail" -path "*/INBOX/new/*" -type f 2>/dev/null | wc -l)
          printf '%s' "$after" > "$count_file"
          new=$(( after - before ))
          if (( new > 0 )); then
            ${pkgs.libnotify}/bin/notify-send \
              --expire-time=5000 --urgency=normal \
              "Mail" "$new new message(s)"
          fi
        else
          find "$HOME/Mail" -path "*/INBOX/new/*" -type f 2>/dev/null \
            | wc -l > "$count_file"
        fi
      '';
    in "${script}";
  };

  # ── msmtp — outgoing mail ────────────────────────────────────────────────────

  programs.msmtp.enable = true;

  # ── neomutt ──────────────────────────────────────────────────────────────────

  programs.neomutt = {
    enable = true;

    sidebar = {
      enable = true;
      width  = 22;
    };

    settings = {
      pager_index_lines = "10";
      pager_context     = "3";

      index_format = ''"%4C %Z  %{%d %b}  %-20.20L  %s"'';

      sidebar_format        = ''"%B%* %?N?(%N) ?%S"'';
      sidebar_short_path    = "yes";
      sidebar_folder_indent = "yes";
      sidebar_indent_string = ''"  "'';

      sort     = "threads";
      sort_aux = "reverse-last-date-received";

      smart_wrap = "yes";
      markers    = "no";

      editor = ''"nvim +/^$ '+set ft=mail'"'';

      mail_check = "60";
      timeout    = "10";
    };

    binds = [
      # ── Index ─────────────────────────────────────────────────────────────
      { map = [ "index" ]; key = "j";  action = "next-entry"; }
      { map = [ "index" ]; key = "k";  action = "previous-entry"; }
      { map = [ "index" ]; key = "l";  action = "display-message"; }
      { map = [ "index" ]; key = "G";  action = "last-entry"; }
      { map = [ "index" ]; key = "g";  action = "noop"; }
      { map = [ "index" ]; key = "gg"; action = "first-entry"; }
      { map = [ "index" ]; key = "m";  action = "mail"; }
      { map = [ "index" ]; key = "u";  action = "toggle-new"; }
      { map = [ "index" ]; key = "s";  action = "save-message"; }

      # ── Pager ─────────────────────────────────────────────────────────────
      { map = [ "pager" ]; key = "j";  action = "next-line"; }
      { map = [ "pager" ]; key = "k";  action = "previous-line"; }
      { map = [ "pager" ]; key = "q";  action = "exit"; }
      { map = [ "pager" ]; key = "G";  action = "bottom"; }
      { map = [ "pager" ]; key = "g";  action = "noop"; }
      { map = [ "pager" ]; key = "gg"; action = "top"; }

      # ── Sidebar ───────────────────────────────────────────────────────────
      { map = [ "index" "pager" ]; key = "J"; action = "sidebar-next"; }
      { map = [ "index" "pager" ]; key = "K"; action = "sidebar-prev"; }

      # ── Actions ───────────────────────────────────────────────────────────
      { map = [ "index" "pager" ]; key = "r"; action = "reply"; }
      { map = [ "index" "pager" ]; key = "R"; action = "group-reply"; }
      { map = [ "index" "pager" ]; key = "d"; action = "delete-message"; }
      { map = [ "index" "pager" ]; key = "v"; action = "view-attachments"; }

      # ── Compose ───────────────────────────────────────────────────────────
      { map = [ "editor" ]; key = "<Tab>"; action = "complete-query"; }
    ];

    macros = [
      { map = [ "index" "pager" ]; key = "o";
        action = "<sidebar-open>"; }

      { map = [ "index" "pager" ]; key = "b";
        action = "<enter-command>toggle sidebar_visible<enter>"; }

      # Account inbox shortcuts
      { map = [ "index" "pager" ]; key = "gi";
        action = "<change-folder>${maildir}/Gmail/INBOX<enter>"; }
      { map = [ "index" "pager" ]; key = "gp";
        action = "<change-folder>${maildir}/GmailProf/INBOX<enter>"; }
      { map = [ "index" "pager" ]; key = "gn";
        action = "<change-folder>${maildir}/NouwensLindemans/INBOX<enter>"; }

      { map = [ "index" "pager" ]; key = "A";
        action = "<pipe-message>abook --add-email-quiet<enter>"; }

      { map = [ "index" "pager" ]; key = "?";
        action = "<shell-escape>bat --style=plain ${config.xdg.configHome}/neomutt/keybindings<enter>"; }
    ];

    extraConfig = ''
      folder-hook '${maildir}/Gmail/'             'set from="${s.gmailAddress}"'
      folder-hook '${maildir}/GmailProf/'         'set from="${s.gmail2Address}"'
      folder-hook '${maildir}/NouwensLindemans/'  'set from="${s.nouwensLindemansAddress}"'

      set query_command = "abook --mutt-query '%s'"

      # ── Colours ────────────────────────────────────────────────────────────
      # Ukiyo palette via Stylix base16 terminal colors:
      #   color0=bg  color1=red  color3=amber  color4=gold
      #   color6=warm-gold  color7=text  color8=dim  color12=secondary

      color normal        color7   default
      color indicator     color0   color3

      color index         color4   default  "~U"
      color index         color1   default  "~D"
      color index         color3   default  "~F"
      color index         color6   default  "~T"

      color index_author  color4   default  "~U"
      color index_subject color4   default  "~U"

      color sidebar_new       color4   default
      color sidebar_indicator color0   color3
      color sidebar_divider   color8   default

      color header     color3   default  "^From:"
      color header     color3   default  "^Subject:"
      color header     color4   default  "^Date:"
      color header     color12  default  "^To:"
      color header     color12  default  "^Cc:"
      color hdrdefault color8   default

      color quoted      color8   default
      color quoted1     color3   default
      color quoted2     color4   default
      color signature   color8   default
      color attachment  color6   default

      color status      color0   color3

      color body  color4  default  "(https?|ftp)://[^ >)]*"
    '';
  };

  # ── Keybinding cheatsheet (press ?) ──────────────────────────────────────────

  xdg.configFile."neomutt/keybindings".text = ''
    Neomutt — key reference
    ─────────────────────────────────────────────────────────

    Navigation
      j / k           up / down in message list
      l / Enter       open message
      gg / G          first / last message
      q               back to message list (from pager)

    Sidebar
      J / K           next / previous folder
      o               open sidebar-highlighted folder
      b               toggle sidebar

    Account shortcuts
      gi              Gmail (tidemanus)
      gp              Gmail Professional (thijmen.nouwens)
      gn              Nouwens-Lindemans

    Actions
      m               compose new message
      r               reply
      R               reply-all
      d               delete message
      s               move message to folder
      u               toggle read / unread
      v               view attachments
      A               add sender to address book

    Compose
      Tab             autocomplete address (from abook)

    Other
      ?               this page

    Press q to close.
  '';
}
