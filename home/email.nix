{ config, ... }:

# ─────────────────────────────────────────────────────────────────────────────
# Before rebuilding, create home/secrets.nix (gitignored) with your addresses:
#
#   {
#     gmailAddress = "you@gmail.com";    # ← FILL IN
#     # add more addresses here as you add accounts
#   }
#
# Then follow the one-time setup steps in plans/Active/email.md.
# ─────────────────────────────────────────────────────────────────────────────

let
  s       = import ./secrets.nix;
  maildir = "${config.home.homeDirectory}/Mail";
in {

  # ── Accounts ────────────────────────────────────────────────────────────────

  accounts.email = {
    maildirBasePath = maildir;

    accounts.Gmail = {
      address  = s.gmailAddress;
      userName = s.gmailAddress;
      realName = "Thijmen Nouwens";
      primary  = true;

      folders = {
        inbox  = "INBOX";
        sent   = "[Gmail]/Sent Mail";
        drafts = "[Gmail]/Drafts";
        trash  = "[Gmail]/Trash";
      };

      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };

      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls = { enable = true; useStartTls = false; };
      };

      # One-time setup: lpass add 'Gmail App Password neomutt'
      passwordCommand = "lpass show --password 'Gmail App Password neomutt'";

      mbsync = {
        enable  = true;
        create  = "maildir";
        expunge = "both";
        # Sync inbox + Gmail special folders only (skip All Mail — too large)
        patterns = [ "INBOX" "[Gmail]/Sent Mail" "[Gmail]/Drafts" "[Gmail]/Trash" ];
      };

      msmtp.enable = true;

      neomutt = {
        enable         = true;
        extraMailboxes = [ "[Gmail]/Sent Mail" "[Gmail]/Drafts" "[Gmail]/Trash" ];
      };
    };
  };

  # ── mbsync — IMAP → local maildir sync ──────────────────────────────────────

  programs.mbsync.enable = true;

  services.mbsync = {
    enable    = true;
    frequency = "*:0/5";  # sync every 5 minutes
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
    ];

    macros = [
      { map = [ "index" "pager" ]; key = "\\Co";
        action = "<sidebar-open>"; }

      { map = [ "index" "pager" ]; key = "b";
        action = "<enter-command>toggle sidebar_visible<enter>"; }

      { map = [ "index" "pager" ]; key = "gi";
        action = "<change-folder>${maildir}/Gmail/INBOX<enter>"; }

      { map = [ "index" "pager" ]; key = "?";
        action = "<shell-escape>bat --style=plain ${config.xdg.configHome}/neomutt/keybindings<enter>"; }
    ];

    extraConfig = ''
      folder-hook '${maildir}/Gmail/' 'set from="${s.gmailAddress}"'
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
      Ctrl+O          open sidebar-highlighted folder
      b               toggle sidebar

    Account shortcuts
      gi              go to Gmail inbox

    Actions
      m               compose new message
      r               reply
      R               reply-all
      d               delete message
      u               toggle read / unread
      v               view attachments

    Other
      ?               this page

    Press q to close.
  '';
}
