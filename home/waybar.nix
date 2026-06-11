{ lib, ... }: {
  programs.waybar = {
    enable = true;

    settings = [{
      layer  = "top";
      height = 28;
      position = "top";

      modules-left   = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "clock" ];
      modules-right  = [ "network" "pulseaudio" "tray" ];

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

      "sway/mode" = {
        format = "  {}";
      };

      "clock" = {
        format         = "{:%H:%M   %a %d %b}";
        tooltip        = false;
      };

      "network" = {
        format-wifi        = "{essid}";
        format-ethernet    = "eth";
        format-disconnected = "no net";
        tooltip-format     = "{ifname}: {ipaddr}";
        max-length         = 20;
      };

      "pulseaudio" = {
        format       = "{volume}%";
        format-muted = "muted";
        on-click     = "pavucontrol";
        scroll-step  = 5;
      };

      "tray" = {
        spacing = 8;
      };
    }];

    # Structural overrides on top of Stylix's colour theme.
    style = lib.mkAfter ''
      * {
          font-family: "JetBrainsMono Nerd Font Mono";
          font-size: 12px;
      }

      #workspaces button {
          padding: 0 10px;
          margin: 3px 2px;
          border-radius: 4px;
          border: none;
          min-width: 0;
      }

      #workspaces button.active {
          font-weight: 600;
      }

      #workspaces button.urgent {
          font-weight: 600;
      }

      #clock {
          padding: 0 16px;
          font-weight: 500;
          letter-spacing: 0.04em;
      }

      #network, #pulseaudio {
          padding: 0 10px;
      }

      #tray {
          padding: 0 8px;
      }

      #mode {
          padding: 0 8px;
          font-weight: 600;
      }
    '';
  };
}
