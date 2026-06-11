{ ... }: {
  services.mako = {
    enable         = true;
    defaultTimeout = 5000;
    maxVisible     = 5;
    anchor         = "top-right";
    margin         = "10";
    padding        = "10";
    borderRadius   = 6;
    # Stylix auto-themes colours from the Ukiyo palette.
  };
}
