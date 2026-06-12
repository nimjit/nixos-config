{ pkgs, ... }: {
  xdg.configFile."nchat/ui.conf".source    = ./dotfiles/nchat/ui.conf;
  xdg.configFile."nchat/color.conf".source = ./dotfiles/nchat/color.conf;
  xdg.configFile."nchat/key.conf".source   = ./dotfiles/nchat/key.conf;

  # Keeps nchat alive in a dtach session so notifications fire even when
  # the kitty tab is closed. messages() attaches; closing the tab detaches.
  systemd.user.services.nchat = {
    Unit = {
      Description = "nchat WhatsApp background session";
      After       = [ "graphical-session.target" ];
      PartOf      = [ "graphical-session.target" ];
    };
    Service = {
      Type            = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.dtach}/bin/dtach -n /tmp/nchat-dtach ${pkgs.nchat}/bin/nchat";
      ExecStop  = pkgs.writeShellScript "stop-nchat" ''
        pkill -f "dtach.*nchat-dtach" 2>/dev/null || true
      '';
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
