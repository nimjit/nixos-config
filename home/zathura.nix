{ ... }: {
  programs.zathura = {
    enable = true;
    options = {
      "selection-clipboard" = "clipboard";  # selected text → Wayland clipboard (Ctrl+V)
    };
    extraConfig = ''
      set window-width 1400
      set window-height 1000
    '';
  };
}
