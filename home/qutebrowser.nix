{ lib, ... }: {

  programs.qutebrowser = {
    enable = true;

    settings = {
      url.start_pages  = [ "http://localhost:8080" ];
      url.default_page = "http://localhost:8080";

      downloads.location.directory = "~/Downloads";
      downloads.location.prompt    = false;

      # Built-in ad/tracker blocking (Easylist format)
      content.blocking.enabled = true;
      content.blocking.method  = "adblock";
      content.blocking.adblock.lists = [
        "https://easylist.to/easylist/easylist.txt"
        "https://easylist.to/easylist/easyprivacy.txt"
        "https://secure.fanboy.com.au/fanboy-annoyance.txt"
      ];

      content.javascript.enabled = true;
      content.autoplay            = false;

      fonts.default_family = lib.mkForce "CMU Typewriter Text";
      fonts.default_size   = lib.mkForce "11pt";

      scrolling.smooth = true;
      tabs.last_close  = "close";

      # Hint keys on home row
      hints.chars = "asdfjkl;";
    };

    keyBindings.normal = {
      # qute-lastpass: fill username+password via LastPass CLI
      "<Alt-p>" = "spawn --userscript qute-lastpass";
    };

    extraConfig = ''
      # ── Google sign-in fix ────────────────────────────────────────────
      # QtWebEngine UA is blocked by Google. Override to plain Chrome UA for
      # all Google domains and googleapis (sign-in redirects through several).
      _chrome_ua = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36'
      for _pattern in [
          'https://accounts.google.com/*',
          'https://*.google.com/*',
          'https://*.googleapis.com/*',
          'https://*.gstatic.com/*',
      ]:
          config.set('content.headers.user_agent', _chrome_ua, _pattern)
          config.set('content.javascript.can_open_tabs_automatically', True, _pattern)

      # ── Stylesheet ───────────────────────────────────────────────────
      # Single file: global.css contains YouTube-specific rules at the bottom
      # (ytd-* selectors are no-ops on other sites).
      c.content.user_stylesheets = ['${./dotfiles/qutebrowser/global.css}']

      # ── Ukiyo color scheme ────────────────────────────────────────────
      _bg  = "#372d29"
      _bgl = "#413632"
      _bga = "#2b2723"
      _fg  = "#ccc2b7"
      _fgm = "#b2a699"
      _fgf = "#868074"
      _acc = "#ba945f"
      _ach = "#e0ba86"
      _err = "#cc4444"

      c.colors.completion.fg                        = _fg
      c.colors.completion.odd.bg                    = _bg
      c.colors.completion.even.bg                   = _bgl
      c.colors.completion.category.fg               = _acc
      c.colors.completion.category.bg               = _bga
      c.colors.completion.category.border.top       = _bga
      c.colors.completion.category.border.bottom    = _bga
      c.colors.completion.item.selected.fg          = _fg
      c.colors.completion.item.selected.bg          = _bgl
      c.colors.completion.item.selected.border.top  = _bgl
      c.colors.completion.item.selected.border.bottom = _bgl
      c.colors.completion.match.fg                  = _ach
      c.colors.completion.scrollbar.fg              = _fgm
      c.colors.completion.scrollbar.bg              = _bga

      c.colors.contextmenu.menu.fg                  = _fg
      c.colors.contextmenu.menu.bg                  = _bg
      c.colors.contextmenu.selected.fg              = _fg
      c.colors.contextmenu.selected.bg              = _bgl

      c.colors.downloads.bar.bg                     = _bga
      c.colors.downloads.start.fg                   = _fg
      c.colors.downloads.start.bg                   = _bgl
      c.colors.downloads.stop.fg                    = _fg
      c.colors.downloads.stop.bg                    = _acc
      c.colors.downloads.error.fg                   = _err

      c.colors.hints.fg                             = _bga
      c.colors.hints.bg                             = _acc
      c.colors.hints.match.fg                       = _fg

      c.colors.keyhint.fg                           = _fg
      c.colors.keyhint.suffix.fg                    = _ach
      c.colors.keyhint.bg                           = _bga

      c.colors.messages.error.fg                    = _bga
      c.colors.messages.error.bg                    = _err
      c.colors.messages.error.border                = _err
      c.colors.messages.warning.fg                  = _bga
      c.colors.messages.warning.bg                  = _acc
      c.colors.messages.warning.border              = _acc
      c.colors.messages.info.fg                     = _fg
      c.colors.messages.info.bg                     = _bgl
      c.colors.messages.info.border                 = _bgl

      c.colors.prompts.fg                           = _fg
      c.colors.prompts.border                       = "1px solid " + _acc
      c.colors.prompts.bg                           = _bg
      c.colors.prompts.selected.fg                  = _fg
      c.colors.prompts.selected.bg                  = _bgl

      c.colors.statusbar.normal.bg                  = _bga
      c.colors.statusbar.normal.fg                  = _fg
      c.colors.statusbar.insert.bg                  = _bgl
      c.colors.statusbar.insert.fg                  = _ach
      c.colors.statusbar.passthrough.bg             = _bgl
      c.colors.statusbar.passthrough.fg             = _fgm
      c.colors.statusbar.private.bg                 = _bga
      c.colors.statusbar.private.fg                 = _fgm
      c.colors.statusbar.command.bg                 = _bga
      c.colors.statusbar.command.fg                 = _fg
      c.colors.statusbar.command.private.bg         = _bga
      c.colors.statusbar.command.private.fg         = _fgm
      c.colors.statusbar.caret.bg                   = _bgl
      c.colors.statusbar.caret.fg                   = _fg
      c.colors.statusbar.caret.selection.bg         = _bgl
      c.colors.statusbar.caret.selection.fg         = _ach
      c.colors.statusbar.progress.bg                = _acc
      c.colors.statusbar.url.fg                     = _fg
      c.colors.statusbar.url.error.fg               = _err
      c.colors.statusbar.url.hover.fg               = _ach
      c.colors.statusbar.url.success.http.fg        = _fgm
      c.colors.statusbar.url.success.https.fg       = _fg
      c.colors.statusbar.url.warn.fg                = _acc

      c.colors.tabs.bar.bg                          = _bga
      c.colors.tabs.indicator.start                 = _acc
      c.colors.tabs.indicator.stop                  = _fg
      c.colors.tabs.indicator.error                 = _err
      c.colors.tabs.odd.bg                          = _bg
      c.colors.tabs.odd.fg                          = _fgm
      c.colors.tabs.even.bg                         = _bg
      c.colors.tabs.even.fg                         = _fgm
      c.colors.tabs.selected.odd.bg                 = _bgl
      c.colors.tabs.selected.odd.fg                 = _fg
      c.colors.tabs.selected.even.bg                = _bgl
      c.colors.tabs.selected.even.fg                = _fg
      c.colors.tabs.pinned.odd.bg                   = _bg
      c.colors.tabs.pinned.odd.fg                   = _fgm
      c.colors.tabs.pinned.even.bg                  = _bg
      c.colors.tabs.pinned.even.fg                  = _fgm
      c.colors.tabs.pinned.selected.odd.bg          = _bgl
      c.colors.tabs.pinned.selected.odd.fg          = _fg
      c.colors.tabs.pinned.selected.even.bg         = _bgl
      c.colors.tabs.pinned.selected.even.fg         = _fg

      c.colors.webpage.bg                           = _bg

      # ── User theme overrides ──────────────────────────────────────────
      # Edit ~/.config/qutebrowser/theme.py freely — no rebuild needed.
      # Reload with :config-source inside qutebrowser.
      import os as _os
      _theme = _os.path.expanduser('~/.config/qutebrowser/theme.py')
      if _os.path.exists(_theme):
          config.source(_theme)
    '';
  };

  # Greasemonkey script — YouTube list view
  xdg.dataFile."qutebrowser/greasemonkey/youtube-listview.js".source =
    ./dotfiles/qutebrowser/greasemonkey/youtube-listview.js;
}
