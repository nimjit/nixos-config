{ username, ... }: {

  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";

    # Overwrite settings declared here even if changed in the web UI
    overrideDevices = true;
    overrideFolders = true;

    settings = {

      # ── Devices ────────────────────────────────────────────────────────
      # Add each device's ID here after first running Syncthing on it.
      # Get the ID from: http://localhost:8384 → Actions → Show ID
      # Or: syncthing --device-id (run as your user)

      devices = {
        # "desktop" = { id = "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX-XXXXX"; };
        # "nas"     = { id = "YYYYY-YYYYY-YYYYY-YYYYY-YYYYY-YYYYY-YYYYY-YYYYY"; };
        # "usb"     = { id = "ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ"; };
      };

      # ── Folders ────────────────────────────────────────────────────────
      folders = {
        "BACKUP" = {
          path = "/home/${username}/BACKUP";
          # List all device names that should sync this folder:
          devices = [ ];  # e.g. [ "desktop" "nas" "usb" ]

          # Keep 30 days of file history (recovers accidentally deleted files)
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000";  # 30 days in seconds
            };
          };
        };
      };

      # ── GUI ────────────────────────────────────────────────────────────
      gui = {
        enabled = true;
        address = "127.0.0.1:8384";  # web UI only accessible locally
      };
    };
  };

  # Open firewall port for Syncthing sync protocol (not the web UI)
  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
