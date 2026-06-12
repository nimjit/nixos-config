{ ... }: {
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      max-visible     = 5;
      anchor          = "top-center";
      margin          = "40,0,0,0";  # clears waybar (28px height + 4px margin-top + buffer)
      width           = 400;         # matches waybar bar width at 4K scale 1.2
      padding         = "10";
      border-radius   = 6;
      # Stylix auto-themes colours from the Ukiyo palette.
    };
  };
}
