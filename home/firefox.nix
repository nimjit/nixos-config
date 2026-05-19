{ pkgs, ... }: {

  programs.firefox = {
    enable = true;

    # NUR provides declarative extension management.
    # You need to add NUR as a flake input for this to work.
    # For now, extensions are commented out; install them manually.
    # (See README for how to add NUR to flake.nix)

    profiles.default = {
      name = "default";
      isDefault = true;

      # ── userChrome.css ──────────────────────────────────────────────────
      userChrome = builtins.readFile ./dotfiles/userChrome.css;

      # ── about:config settings ───────────────────────────────────────────
      settings = {
        # Required for userChrome.css to take effect
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

        # UI preferences
        "browser.tabs.inTitlebar" = 0;
        "browser.uidensity" = 1;           # compact density
        "browser.startup.page" = 3;        # restore previous session
        "browser.sessionstore.resume_from_crash" = true;

        # Privacy
        "privacy.donottrackheader.enabled" = true;
        "geo.enabled" = false;
        "browser.safebrowsing.malware.enabled" = false;
        "browser.safebrowsing.phishing.enabled" = false;

        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };

      # ── Extensions (requires NUR) ───────────────────────────────────────
      # Uncomment after adding NUR to flake.nix:
      # extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      #   ublock-origin
      #   stylus
      #   bitwarden
      # ];
    };
  };
}
