{ lib, ... }: {
  programs.waybar = {
    enable = true;

    settings = [{
      layer    = "top";
      position = "top";
      height   = 28;

      # Narrow centered bar — 4K @ scale 1.2 = 3200 logical px; these give ~400px wide
      margin-top   = 4;
      margin-left  = 1400;
      margin-right = 1400;

      modules-left   = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      modules-right  = [ "tray" ];

      "sway/workspaces" = {
        disable-scroll = true;
        format         = "{name}";
        persistent-workspaces = {
          "Uni"     = [];
          "General" = [];
          "Extra"   = [];
          "NixOS"   = [];
        };
      };

      "sway/mode".format = " {}";

      "clock" = {
        format  = "{:%H:%M   %a %d %b}";
        tooltip = false;
      };

      "tray".spacing = 8;
    }];

    style = lib.mkForce ''
      * {
          font-family: "JetBrainsMono Nerd Font Mono";
          font-size: 12px;
          border: none;
          border-radius: 0;
      }

      window#waybar {
          background-color: #372d29;
          border: 1px solid #504431;
          border-radius: 6px;
          color: #ccc2b7;
      }

      #workspaces {
          margin: 0 4px;
      }

      #workspaces button {
          background-color: #413632;
          color: #868074;
          padding: 0 12px;
          margin: 3px 2px;
          border-radius: 4px;
          min-width: 0;
      }

      #workspaces button:hover {
          background-color: #504431;
          color: #ccc2b7;
      }

      #workspaces button.active {
          background-color: #504431;
          color: #e0ba86;
          font-weight: 600;
      }

      #workspaces button.urgent {
          color: #da9517;
      }

      #clock {
          color: #ccc2b7;
          padding: 0 16px;
          font-weight: 500;
          letter-spacing: 0.04em;
      }

      #mode {
          color: #da9517;
          font-weight: 600;
          padding: 0 10px;
      }

      #tray {
          padding: 0 8px;
          color: #868074;
      }
    '';
  };
}
