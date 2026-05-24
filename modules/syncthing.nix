{ username, ... }: {

  services.syncthing = {
    enable = true;
    user = username;
    dataDir = "/home/${username}";
    configDir = "/home/${username}/.config/syncthing";
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices = {
        "nixos-desktop" = {
          id = "YPJSINR-FPTEDVK-56OB5L6-JGBJ5DE-22PZW7X-CH7RC7F-NUEASLF-TIEJDQD";
          addresses = [ "tcp://100.75.233.85" ]  # Tailscale address of nixos desktop - can be found at https://login.tailscale.com/admin/machines
        };
        "zbook-laptop" = {
          id = "3ACFKE4-5UVT2RY-EVWAAPS-DHTL7UZ-MANAYII-WELOAWM-LYCT5O5-2KHI3QJ";
          addresses = [ "tcp://100.74.207.5" ];  # Tailscale address of zbook
        };
        # "nas" = { id = ""; };
        # "usb" = { id = ""; };
      };

      folders = {
        # First folder: BACKUP at /home/thijmen/BACKUP
        "BACKUP" = {
          path = "/home/${username}/BACKUP";
          devices = [ "nixos-desktop" "zbook-laptop" ];
          versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000";
            };
          };
        };

        # Second folder: Documents/BACKUP synced with both devices
        "vq5vt-g7nas" = {
          label = "Documents";
          path = "/home/${username}/Documents/BACKUP";
          devices = [ "nixos-desktop" "zbook-laptop" ];
          ignores.lines = [
            # Git repositories - sync files but not git internals
            "**/.git"
            "(?d) **/.DS_Store"
            "(?d) **/Thumbs.db"

            # System files
            ".DS_Store"
            "Thumbs.db"
            "desktop.ini"

            # Syncthing conflict files
            "*.sync-conflict-*"

            # Obsidian json files
            "**/.obsidian/**/*.json"
            "!**/.obsidian/community-plugins.json"
            "!**/.obsidian/snippets/**"

            # I want to sync Music Library, but not the Music Library symlink:
            "Music Library"
            "!Music Library/**"
            ];
            versioning = {
            type = "staggered";
            params = {
              cleanInterval = "3600";
              maxAge = "2592000";
            };
          };
        };
      };

      options = {
        globalAnnounceEnabled = false;  
        localAnnounceEnabled = true;
        relaysEnabled = false;         
        urAccepted = -1;              
      };

      gui = {
        enabled = true;
        address = "127.0.0.1:8384";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 22000 ];
  networking.firewall.allowedUDPPorts = [ 22000 21027 ];
}
