{ pkgs, lib, ... }:
let
  mod = "Mod4";
  wallpaper = "${../themes/wallpapers/Pieter_Bruegel-Childrens_Games.jpg}";
in {
  wayland.windowManager.sway = {
    enable      = true;
    systemd.enable = true;
    checkConfig = false;  # Nix build sandbox has no DRM/GPU access; skip the validator

    # Nvidia + Wayland env vars scoped to the sway session only — not inherited by KDE.
    extraSessionCommands = ''
      export WLR_NO_HARDWARE_CURSORS=1
      export WLR_RENDERER=vulkan
      export QT_QPA_PLATFORM=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
    '';

    config = {
      modifier = mod;
      terminal = "kitty";

      gaps   = { inner = 6; outer = 4; smartGaps = true; };
      window = { border = 2; titlebar = false; };

      floating.modifier = mod;

      input = {
        "type:keyboard" = {
          xkb_layout   = "us";
          repeat_delay = "200";
          repeat_rate  = "60";
        };
        "type:pointer" = {
          accel_profile = "flat";
        };
      };

      output = {
        "*" = {
          scale = "1.2";
          bg    = "${wallpaper} fill";
        };
      };

      keybindings = lib.mkOptionDefault {
        # Workspace switching — Meta+HJKL ordered left→right = Uni/General/Extra/NixOS
        "${mod}+h"       = "workspace Uni";
        "${mod}+j"       = "workspace General";
        "${mod}+k"       = "workspace Extra";
        "${mod}+l"       = "workspace NixOS";

        # Move window to workspace
        "${mod}+Shift+h" = "move container to workspace Uni";
        "${mod}+Shift+j" = "move container to workspace General";
        "${mod}+Shift+k" = "move container to workspace Extra";
        "${mod}+Shift+l" = "move container to workspace NixOS";

        # Focus window — Meta+Arrows
        "${mod}+Left"       = "focus left";
        "${mod}+Right"      = "focus right";
        "${mod}+Up"         = "focus up";
        "${mod}+Down"       = "focus down";

        # Move window — Meta+Shift+Arrows
        "${mod}+Shift+Left"  = "move left";
        "${mod}+Shift+Right" = "move right";
        "${mod}+Shift+Up"    = "move up";
        "${mod}+Shift+Down"  = "move down";

        # Apps
        "${mod}+Return"      = "exec kitty";
        "Mod1+space"         = "exec rofi -show combi";
        "${mod}+w"           = "exec rofi -show window";

        # Layout
        "${mod}+f"           = "fullscreen toggle";
        "${mod}+e"           = "layout toggle split";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space"       = "focus mode_toggle";
        "${mod}+r"           = "mode resize";

        # Kill
        "${mod}+Shift+q" = "kill";

        # Screenshots to ~/Pictures/Screenshots/
        "Print"          = "exec grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png";
        "${mod}+Print"   = ''exec grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png'';

        # Volume (PipeWire / wireplumber)
        "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute"        = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioPlay"        = "exec playerctl play-pause";
        "XF86AudioNext"        = "exec playerctl next";
        "XF86AudioPrev"        = "exec playerctl previous";

        # Reload / exit
        "${mod}+Shift+c" = "reload";
        "${mod}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes, exit' 'swaymsg exit'";
      };

      floating.criteria = [
        { app_id = "org.gnome.Polkit"; }
        { app_id = "nm-connection-editor"; }
        { title  = "^Open File$"; }
        { title  = "^Save File$"; }
      ];

      bars = [];  # waybar replaces the built-in bar

      startup = [
        { command = "waybar"; }
        { command = "mako"; }
        { command = "nm-applet --indicator"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        # Night colour: 6500 K during day, 5000 K warm from 20:00 onward
        { command = "wlsunset -t 5000 -T 6500 -S 07:00 -s 20:00"; }
        { command = "mkdir -p ~/Pictures/Screenshots"; }
      ];
    };
  };
}
