{ ... }: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      max-visible     = 5;
      anchor          = "top-right";
      margin          = "10";
      padding         = "10";
      border-radius   = 6;
      # Stylix auto-themes colours from the Ukiyo palette.
    };
  };
}
