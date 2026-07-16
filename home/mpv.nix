{ pkgs, ... }: {

  programs.mpv = {
    enable = true;
    scripts = with pkgs.mpvScripts; [
      uosc          # modern minimal UI (replaces default progress bar)
      thumbfast     # thumbnail previews on seek bar
      sponsorblock  # auto-skip YouTube sponsor segments
    ];
    config = {
      # Video
      hwdec = "auto-safe";          # hardware decoding where possible
      vo = "gpu";
      gpu-context = "wayland";      # force native Wayland/EGL path; auto-detect picks broken dmabuf path on NVIDIA
      profile = "gpu-hq";

      # Audio
      audio-normalize-downmix = true;
      volume = 100;
      volume-max = 150;

      # Subtitles
      sub-auto = "fuzzy";           # find subtitles with similar filenames
      sub-font-size = 40;

      # Behaviour
      save-position-on-quit = true; # resume where you left off
      keep-open = true;             # don't close after playback ends
      osd-bar = false;              # cleaner OSD
    };

    # Keybindings on top of the defaults
    bindings = {
      "WHEEL_UP"   = "seek 10";
      "WHEEL_DOWN" = "seek -10";
      "Alt+0"      = "set window-scale 0.5";
      "Alt+1"      = "set window-scale 1";
      "Alt+2"      = "set window-scale 2";
    };
  };
}
