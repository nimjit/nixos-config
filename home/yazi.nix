{ ... }: {

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      manager = {
        show_hidden = true;
        show_symlink = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
      preview = {
        image_quality = 75;
        max_width = 1200;
        max_height = 1800;
      };
    };

    keymap = {
      manager.prepend_keymap = [
        { on = [ "l" ]; run = "enter"; desc = "Enter directory or open file"; }
      ];
    };

    # Shell function: pressing 'y' in the terminal opens Yazi,
    # and when you quit, your shell is left in the directory you were browsing.
    # This is the idiomatic way to use Yazi.
    shellWrapperName = "y";
  };
}
