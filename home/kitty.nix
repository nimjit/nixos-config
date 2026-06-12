{ config, ... }: {

  programs.kitty = {
    enable = true;
    # Stylix writes all colour values automatically.
    # Only put non-colour settings here.
    settings = {
      font_size = "13.0";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      window_padding_width = 8;
      hide_window_decorations = "yes";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      # Required for messages() and music() to manage kitty tabs via 'kitty @'
      allow_remote_control = "yes";
      listen_on = "unix:/tmp/kitty-control";
      # splits layout required for --location=vsplit to open panels side-by-side
      enabled_layouts = "splits,stack";
      # Open messages tab (nchat) in background + home tab on startup
      startup_session = "${config.xdg.configHome}/kitty/startup.session";
      # Minimal cursor trail: single cell, fast fade, triggers on ≥2 cell moves
      cursor_trail = 1;
      cursor_trail_decay = "0.1 0.2";
      cursor_trail_start_threshold = 9;
    };

    keybindings = {
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+t"     = "new_tab_with_cwd";
      # Window navigation — ctrl+hjkl is reserved for neovim split nav;
      # ctrl+shift+hjkl navigates kitty panels (e.g. PDF/image preview splits)
      "ctrl+shift+h" = "neighboring_window left";
      "ctrl+shift+j" = "neighboring_window bottom";
      "ctrl+shift+k" = "neighboring_window top";
      "ctrl+shift+l" = "neighboring_window right";
      # Disable kitty's default linear window cycling (use hjkl directional nav instead)
      "ctrl+shift+]" = "no_op";
      "ctrl+shift+[" = "no_op";
    };
    extraConfig = ''
      foreground #ccc2b7
      background #372d29
      color8 #ccc2b7
      '';
  };
}
