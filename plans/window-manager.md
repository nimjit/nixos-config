# Window Manager Switch Plan

## Current KDE settings (reference for migration)

Captured from live config files. Use this when writing the sway config.

### Virtual desktops
4 desktops in a single row:
| # | Name    | Tiling layout (left monitor) | Tiling layout (right monitor)|
|---|---------|------------------------------|------------------------------|
| 1 | Uni     | 50 / 50                      | 100                          |
| 2 | General | 100                          | 100                          |
| 3 | Extra   | 50 / 50                      | 100                          |
| 4 | Nix-OSrc| 50 / 50                      | 100                          |

Padding: 15px on all desktops. 

### Keyboard shortcuts (non-obvious / custom)
Standard media keys and volume keys are all default — already covered in the
sway plan. The custom / remapped ones that I want to keep in some way:

| Shortcut       | Action                    | Notes for sway                                 |
|----------------|---------------------------|------------------------------------------------|
| `Meta+H/J/K/L` | Switch to desktop 1/2/3/4 | ✓ already in sway plan                         |
| `Alt+H/J/K/L`  | Focus window <-/down/up/->| Add to sway keybindings *(or focus 1/2/3/4)*   |
| `Meta+Return`  | Launch kitty              | ✓ already in sway plan                         |
| `Alt+Space`    | Rofi                      | Keep as-is                                     |
| `Meta+W`       | Overview (all windows)    | Could bind to `rofi -show window` in sway      |
| `Meta+V`       | Show clipboard at cursor  | Add `cliphist` + rofi clipboard picker in sway |
| `Prntscrn`     | Screenshot                | ?                                              |
| `Meta+l drag`  | Move floating window      | ?                                              |
| `Meta+r drag`  | Scale floating window     | ?                                              |

### Display / input
- **Xwayland scale**: 1.2 — set `output * scale 1.2` in sway config
- **Keyboard repeat delay**: 200 ms — ✓ already in sway plan
- **Keyboard repeat rate**: 60/s — sway plan currently has 40, update to 60
- **Focus**: `DelayFocusInterval=0` (instant) — set `focus_follows_mouse yes` in sway if desired

### Night colour
- Enabled, 5000 K (slightly warm). Use `gammastep` or `wlsunset` in sway startup.

### Screen lock / idle
- **Auto-lock**: 30 minutes idle (no auto-suspend on AC) *maybe not even needed*
- **Lock on resume from sleep**: off
- Sway plan currently has 4 min dim + 8 min lock — update swayidle to `timeout 1800 'swaylock'`

### Panel / tray (for Waybar reference)
System tray contains: device notifier, clipboard, notifications, volume, keyboard
indicator, network, battery indicator. All covered by Waybar's `tray` module.
System tray is hidden and located in the bottom right *this could be moved, I don't go here pretty much ever*

Another panel is located middle top, always visible, showing the 4 virtual desktops, the time, and date.
It does not extend to the edge of the screen. *I don't need much here, but I like seeing the time and the desktops just kind of looks neat. I prefer blocks over just the number*

---

## Answered questions

- **WM choice**: Sway — no animations/transparency wanted, stability preferred.
- **KDE apps in use**: krunner (→ rofi, already configured), virtual desktop widget
  (→ sway workspaces), okular rarely (keep in packages or use zathura),
  file save dialogs (→ xdg-desktop-portal-gtk), NetworkManager applet.
- **Sleep/hibernate**: disabled. Screen dims + locks — swayidle handles this.
- **Monitors**: two, same scaling. Need to set output positions in config.
- **No KDE Connect** in use — drop it.
- **Style**: no animations, no blur, no transparency. Square corners, flat look.

## Remaining open questions

- [ ] **Nvidia + Wayland**: you have legacy_535 drivers. Need to test which renderer
      works — `vulkan` first, fall back to `gles2`. This is the main risk.
      Another option is switching to X11, we still need to discuss what the differences are between them.
- [ ] **Monitor IDs**: run `swaymsg -t get_outputs` after first sway launch to get
      exact output names (e.g. `DP-1`, `HDMI-A-1`) for positioning config.
- [ ] **Okular**: do you want to keep it? `zathura` handles most PDFs already.
      Python output PDFs are also fine in zathura (`zathura file.pdf`).
- [ ] **KWallet**: Firefox may prompt for KWallet on first Wayland launch.
      Decide whether to set up a lighter keyring (gnome-keyring) or disable it.
- [ ] **Screen sharing**: do you need it in Firefox/video calls? Needs
      `xdg-desktop-portal-wlr` — include it regardless, low cost.

---

## Testing strategy — nested Wayland (recommended)

Since KDE Plasma 6 runs on Wayland, any Wayland compositor supports running **nested**
inside it — sway opens as a regular window within your existing KDE session.
This is the cleanest testing approach: no logout, no TTY switching, full KDE available
as fallback.

**How it works:**
KDE sets `$WAYLAND_DISPLAY`. When you launch `sway` from within a KDE terminal,
it detects this and uses `WLR_BACKENDS=wayland` automatically — sway appears as
a window in KDE. You get a fully functional sway environment to test in.

**The "flake" angle you were thinking of:**
You don't need a separate flake for this. The approach is:
1. Add `programs.sway.enable = true` to the NixOS config (makes sway available)
2. Rebuild
3. From kitty inside KDE, run: `sway`

That's it. Sway launches as a nested window. Your `wayland.windowManager.sway`
home-manager config applies. Edit `home/sway.nix`, rebuild, restart the nested
sway to see changes — all without ever leaving KDE.

**Cleanup when done testing:** just close the sway window and carry on in KDE.
Only when you're satisfied do you switch the display manager to sway.

If you want to test with zero config changes first:
```bash
nix shell nixpkgs#sway --command sway
# or:
nix run nixpkgs#sway
```
This runs the upstream sway with a default config — useful to verify Nvidia works
before writing any of your own config.

---

## Testing strategy — SDDM session (alternative)

Keep SDDM + KDE running. Sway becomes a parallel SDDM session.
At login screen: select "sway". Switch back to KDE anytime — nothing is removed.

For syntax testing without logging out:
```bash
sway --unsupported-gpu  # nested inside KDE (slower, checks config only)
```

---

## Phase 0 — Inventory (no nix changes)

1. Check your current KDE global shortcuts: System Settings → Shortcuts.
   Write down anything beyond Super+hjkl (media keys, volume, brightness, custom).
2. Check monitor names and positions in KDE Display Settings.
3. Confirm: `xrandr` or `kscreen-doctor -o` shows both monitors and their IDs.

---

## Phase 1 — System-level sway additions

### `hosts/desktop/default.nix`
```nix
# Sway as a selectable WM (KDE stays untouched)
programs.sway = {
  enable = true;
  wrapperFeatures.gtk = true;  # fixes GTK file dialogs and theming
};

# Nvidia + Wayland environment (apply globally so sway session inherits them)
environment.sessionVariables = {   # Can this mess with stability? I've had issues with stuff like this.
  WLR_NO_HARDWARE_CURSORS = "1";   # required for Nvidia cursor rendering
  WLR_RENDERER            = "vulkan";  # try vulkan; change to "gles2" if blank screen
  NIXOS_OZONE_WL          = "1";   # Electron apps use Wayland
  MOZ_ENABLE_WAYLAND      = "1";   # Firefox native Wayland
  QT_QPA_PLATFORM         = "wayland";
  _JAVA_AWT_WM_NONREPARENTING = "1";
};

programs.xwayland.enable = true;  # X11 app compatibility

# Screen sharing from Firefox / any Wayland app *I've never screen shared so far, so it's okay if this doesn't really work well*
xdg.portal = {
  enable = true;
  wlr.enable = true;
  extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
};
```

### Add to `modules/common.nix` packages:
```nix
# Wayland / sway support tools
grim slurp           # screenshots (replaces Spectacle)
wl-clipboard         # wl-copy / wl-paste
swaylock             # screen lock
swayidle             # screen dim + auto-lock
brightnessctl        # brightness keys
playerctl            # media keys
networkmanagerapplet # nm-applet tray icon
polkit_gnome         # privilege dialogs (sudo GUI prompts)
```

---

## Phase 2 — Home Manager sway config

### `home/sway.nix` — new file
```nix
{ pkgs, config, ... }:
let
  mod = "Mod4";  # Super key
in {
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;  # sway integrates with systemd user session

    config = {
      modifier = mod;
      terminal = "kitty";
      menu     = "rofi -show drun -show-icons";
      fonts    = { names = [ "JetBrainsMono Nerd Font Mono" ]; size = 0.0; };

      gaps   = { inner = 6; outer = 2; smartGaps = true; };
      window = { border = 2; titlebar = false; };

      # ── Input ───────────────────────────────────────────────────────────
      input = {
        "type:keyboard" = {
          xkb_layout   = "us";
          repeat_delay = "200";
          repeat_rate  = "40";
        };
        "type:pointer" = {
          accel_profile = "flat";
        };
      };

      # ── Output ──────────────────────────────────────────────────────────
      # Fill in real names after first launch: swaymsg -t get_outputs
      output = {
        "*"    = { bg = "${config.stylix.image} fill"; };
        # "DP-1"     = { resolution = "1920x1080"; position = "0,0"; };
        # "HDMI-A-1" = { resolution = "1920x1080"; position = "1920,0"; };
      };

      # ── Workspaces → Super+hjkl (matches KDE virtual desktops) ─────────
      keybindings = {
        # Workspace switching
        "${mod}+h"       = "workspace number 1";
        "${mod}+l"       = "workspace number 2";
        "${mod}+j"       = "workspace number 3";
        "${mod}+k"       = "workspace number 4";

        # Move window to workspace
        "${mod}+Shift+h" = "move container to workspace number 1";
        "${mod}+Shift+l" = "move container to workspace number 2";
        "${mod}+Shift+j" = "move container to workspace number 3";
        "${mod}+Shift+k" = "move container to workspace number 4";

        # Focus window within workspace
        "${mod}+Left"        = "focus left";
        "${mod}+Right"       = "focus right";
        "${mod}+Up"          = "focus up";
        "${mod}+Down"        = "focus down";

        # Move window within workspace
        "${mod}+Shift+Left"  = "move left";
        "${mod}+Shift+Right" = "move right";
        "${mod}+Shift+Up"    = "move up";
        "${mod}+Shift+Down"  = "move down";

        # Resize mode
        "${mod}+r"           = "mode resize";

        # Layout
        "${mod}+f"           = "fullscreen toggle";
        "${mod}+Shift+space" = "floating toggle";
        "${mod}+space"       = "focus mode_toggle";
        "${mod}+e"           = "layout toggle split";

        # Apps
        "${mod}+Return"      = "exec kitty";
        "${mod}+d"           = "exec rofi -show drun -show-icons";
        "${mod}+Shift+q"     = "kill";

        # Screenshot: full screen / region select
        "Print"              = "exec grim ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png";
        "${mod}+Print"       = "exec grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png";

        # Screen lock
        "${mod}+Escape"      = "exec swaylock";

        # Volume (pipewire/wireplumber)
        "XF86AudioRaiseVolume"  = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
        "XF86AudioLowerVolume"  = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        "XF86AudioMute"         = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        "XF86AudioPlay"         = "exec playerctl play-pause";
        "XF86AudioNext"         = "exec playerctl next";
        "XF86AudioPrev"         = "exec playerctl previous";

        # Brightness
        "XF86MonBrightnessUp"   = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

        # Reload / exit
        "${mod}+Shift+c"     = "reload";
        "${mod}+Shift+e"     = "exec swaynag -t warning -m 'Exit sway?' -B 'Yes, exit' 'swaymsg exit'";
      };

      # ── Floating exceptions ─────────────────────────────────────────────
      floating.criteria = [
        { app_id = "org.kde.polkit-kde-authentication-agent-1"; }
        { app_id = "nm-connection-editor"; }
        { title  = "^Open File$"; }
        { title  = "^Save File$"; }
      ];

      bars = [];  # waybar replaces sway's built-in bar

      # ── Startup ─────────────────────────────────────────────────────────
      startup = [
        { command = "waybar"; }
        { command = "mako"; }
        { command = "nm-applet --indicator"; }
        { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; }
        # Dim after 4 min, lock after 8 min — no suspend (machine never sleeps)
        { command = ''
            swayidle -w \
              timeout 240 'brightnessctl -s set 20%' \
              resume      'brightnessctl -r' \
              timeout 480 'swaylock -f' \
              before-sleep 'swaylock -f'
          ''; }
      ];
    };
  };
}
```

### Add to `home/default.nix` imports:
```nix
./sway.nix
./waybar.nix
./mako.nix
```

---

## Phase 3 — Waybar

### `home/waybar.nix` — new file
```nix
{ ... }: {
  programs.waybar = {
    enable = true;
    settings = [{
      layer  = "top";
      height = 26;
      modules-left   = [ "sway/workspaces" "sway/mode" "sway/window" ];
      modules-center = [ "clock" ];
      modules-right  = [ "pulseaudio" "network" "cpu" "memory" "tray" ];

      "sway/workspaces" = {
        disable-scroll = true;
        all-outputs    = false;
        format         = "{index}";
      };
      "sway/window" = { max-length = 60; };
      "clock"       = { format = "{:%H:%M  %a %d %b}"; tooltip = false; };
      "cpu"         = { format = "cpu {usage}%"; interval = 5; };
      "memory"      = { format = "mem {percentage}%"; interval = 10; };
      "network"     = {
        format-wifi       = "wifi {essid}";
        format-ethernet   = "eth {ifname}";
        format-disconnected = "no network";
      };
      "pulseaudio"  = {
        format       = "vol {volume}%";
        format-muted = "muted";
        on-click     = "pavucontrol";
      };
      "tray"        = { spacing = 8; };
    }];
    # Stylix auto-generates waybar colors from Ukiyo palette — no manual CSS needed.
    # Add style overrides in home/dotfiles/waybar/style.css if you want tweaks.
  };
}
```

---

## Phase 4 — Mako (notifications)

### `home/mako.nix` — new file
```nix
{ ... }: {
  services.mako = {
    enable          = true;
    defaultTimeout  = 5000;
    maxVisible      = 5;
    # Stylix themes mako automatically from Ukiyo palette.
    # Extra options if needed:
    # anchor        = "top-right";
    # margin        = "10";
    # padding       = "8";
    # borderRadius  = 0;  # square corners
  };
}
```

---

## Phase 5 — Testing checklist

After `rebuild`, log out → select **sway** in SDDM login screen.

**First boot checks:**
- [ ] Sway launches (no black screen — if so, see Nvidia notes below)
- [ ] Both monitors detected: `swaymsg -t get_outputs`
- [ ] Waybar visible on primary monitor with workspaces, clock, tray

**Core functionality:**
- [ ] Super+hjkl switches between workspaces 1–4
- [ ] Super+Return opens kitty
- [ ] Super+d opens rofi
- [ ] Kill window with Super+Shift+q
- [ ] Float toggle with Super+Shift+Space
- [ ] Fullscreen with Super+f

**Apps:**
- [ ] Firefox launches and renders correctly (check `MOZ_ENABLE_WAYLAND=1` active)
- [ ] Neovim in kitty works
- [ ] yazi works
- [ ] nchat works
- [ ] mpv plays a video (check `mpv --vo=gpu file`)
- [ ] rofi opens (already configured, should be identical)

**System:**
- [ ] Volume keys adjust volume
- [ ] Screenshot saves to ~/Pictures/Screenshots/
- [ ] `notify-send "test" "hello"` shows mako notification
- [ ] Screen dims after ~4 min idle, locks after ~8 min
- [ ] Super+Escape locks screen
- [ ] NetworkManager applet visible in tray, wifi connects
- [ ] Polkit dialog appears for sudo GUI actions

**Screen sharing (optional):**
- [ ] Open Firefox, go to a screen-share test site, confirm portal dialog appears

---

## If Nvidia gives a black screen

Try in order:
1. Change `WLR_RENDERER = "gles2"` (remove vulkan line)
2. Add `WLR_DRM_NO_ATOMIC = "1"` to sessionVariables
3. Check `journalctl --user -b -u sway` for the actual error
4. Fallback plan: switch to Hyprland, which has more active Nvidia fixes
   (config structure is ~80% similar — same waybar/mako/portal setup)

---

## Phase 6 — Migration (once testing is complete)

1. Remove from `hosts/desktop/default.nix`:
   ```nix
   # services.desktopManager.plasma6.enable = true;
   # environment.plasma6.excludePackages = ...;
   ```
2. Optionally replace SDDM with `greetd` + `tuigreet` (lighter TUI login):
   ```nix
   services.greetd = {
     enable = true;
     settings.default_session = {
       command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd sway";
       user    = "greeter";
     };
   };
   ```
3. Remove any KDE-specific packages from common.nix
4. Update CLAUDE.md
