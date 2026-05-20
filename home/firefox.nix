{ ... }: {

  programs.firefox = {
    enable = true;

    profiles."an03u17w.default" = {
      name = "an03u17w.default";
      isDefault = true;
      userChrome = builtins.readFile ./dotfiles/userChrome.css;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "browser.tabs.inTitlebar" = 0;
        "browser.uidensity" = 1;
        "browser.startup.page" = 3;
        "browser.sessionstore.resume_from_crash" = true;
        "privacy.donottrackheader.enabled" = true;
        "geo.enabled" = false;
        "gfx.webrender.all" = true;
        "media.ffmpeg.vaapi.enabled" = true;
      };
    };
  };
  stylix.targets.firefox.profileNames = [ "an03u17w.default" ];
}
