{ pkgs, lib, ... }: {

  programs.firefox = {
    enable = true;

    profiles.default = {
      name = "default";
      isDefault = true;

      # ── userChrome.css ──────────────────────────────────────────────────
      # Safely reads userChrome.css only if the file exists on disk.
      # Remember: If inside a Git/Flake directory, this file MUST be tracked by Git!
      userChrome = if builtins.pathExists ./dotfiles/userChrome.css
                   then builtins.readFile ./dotfiles/userChrome.css
                   else "";

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
        
        # Note: Modern Firefox copies may override these silently unless forced via policies
        "browser.safebrowsing.malware.enabled" = false;
        "browser.safebrowsing.phishing.enabled" = false;

        # Performance
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };

      # ── Extensions (Safe NUR handling) ──────────────────────────────────
      # This block automatically evaluates to an empty list unless you 
      # explicitly pass NUR into your Home Manager context, preventing compilation crashes.
      # extensions =
      #   if pkgs != null && pkgs ? nur
      #   then with pkgs.nur.repos.rycee.firefox-addons; [
      #     ublock-origin
      #     stylus
      #     bitwarden
      #   ]
      #   else [ ];
      #     };
    };
};
