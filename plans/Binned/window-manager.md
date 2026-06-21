# Window Manager Migration (Binned)

**Decision: staying on KDE + Krohnkite.** KDE tiling via Krohnkite covers the
use case; the Sway migration added complexity without enough upside. Binned
2026-06-21.

---

## What's stored here

- `plans/Binned/sway.nix` — Home Manager sway config (was `home/sway.nix`)
- `plans/Binned/waybar.nix` — Waybar config (was `home/waybar.nix`)

To re-activate: move both .nix files back to `home/`, add them to `home/default.nix`
imports, and add `programs.sway.enable = true` to `hosts/desktop/default.nix`
(requires permission — that file is off-limits by default).

---

## What was achieved

Sway was implemented and built successfully. Tested **nested inside KDE** (run
`sway` from kitty → opens as a KDE window). Build succeeded after:

- `checkConfig = false` (Nix sandbox has no GPU access)
- `mako settings.*` rename
- Removing `fonts.size` conflict with Stylix

Waybar appeared with named workspace blocks (Uni/General/Extra/NixOS) and clock.
Ukiyo CSS applied. All `Meta+*` keybindings were **not** testable nested (KDE
intercepts Super globally).

---

## KDE reference config (kept for if migration resumes)

Virtual desktops: 4 in a single row (Uni / General / Extra / NixOS).
Keyboard repeat: delay 200ms, rate 60/s.
Focus: instant (DelayFocusInterval=0).
Night colour: 5000 K, on from 20:00.

### Nvidia / Wayland notes

If resumed: try `WLR_RENDERER=vulkan` first. If blank screen:
1. Change to `WLR_RENDERER=gles2`
2. Add `WLR_DRM_NO_ATOMIC=1`
3. Check `journalctl --user -b -u sway`
4. Fallback: Hyprland (~80% config compatible)
