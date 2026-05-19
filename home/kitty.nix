{ ... }: {

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
    };

    keybindings = {
      "ctrl+shift+enter" = "new_window_with_cwd";
      "ctrl+shift+t" = "new_tab_with_cwd";
    };
  };
}
