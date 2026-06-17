{ pkgs, ... }: {
  xdg.configFile."nchat/ui.conf".source    = ./dotfiles/nchat/ui.conf;
  xdg.configFile."nchat/color.conf".source = ./dotfiles/nchat/color.conf;
  xdg.configFile."nchat/key.conf".source   = ./dotfiles/nchat/key.conf;
  xdg.configFile."kitty/startup.session".source = ./dotfiles/kitty/startup.session;

  systemd.user.services.nchat = {
    Unit = {
      Description = "nchat WhatsApp background session";
      After       = [ "graphical-session.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type            = "oneshot";
      RemainAfterExit = true;
      Restart         = "on-failure";
      RestartSec      = "5";
      ExecStart = let
        start = pkgs.writeShellScript "start-nchat" ''
          export TERM=xterm-256color
          stty cols 220 rows 50
          exec ${pkgs.nchat}/bin/nchat
        '';
      in "${pkgs.dtach}/bin/dtach -n /tmp/nchat-dtach ${start}";
      ExecStop = pkgs.writeShellScript "stop-nchat" ''
        pkill -f "dtach.*nchat-dtach" 2>/dev/null || true
      '';
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
