{ config, ... }: {

  services.mpd = {
    enable = true;
    # Point this at wherever your local music files live.
    # ~/Music is the XDG default; change if needed.
    musicDirectory = "${config.home.homeDirectory}/Music";
    extraConfig = ''
      audio_output {
        type "pipewire"
        name "PipeWire Output"
      }
    '';
  };
}
