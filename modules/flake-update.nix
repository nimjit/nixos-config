{ config, pkgs, ... }:

{
  systemd.services.nixos-flake-update = {
    description = "Update flake inputs and rebuild";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    # Provides nixos-rebuild with the core tools it needs to run
    path = with pkgs; [ 
      nix 
      git 
      openssh 
      coreutils 
      nettools # provides 'hostname' command if needed
    ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = pkgs.writeShellScript "nixos-flake-update" ''
        cd /etc/nixos

        if [ ! -d ".git" ]; then
          echo "Not a git repo, skipping"
          exit 0
        fi

        echo "Updating flake inputs..."
        nix flake update

        echo "Committing updated flake.lock..."
        git add flake.lock
        git commit -m "auto: update flake inputs $(date +%Y-%m-%d)" || {
          echo "Nothing to commit, inputs already up to date"
          exit 0
        }
        
        echo "Pushing changes..."
        git push

        echo "Rebuilding..."
        # Escaped \$ ensures Bash reads the hostname at runtime
        nixos-rebuild switch --flake /etc/nixos#desktop
      '';
    };
  };

  systemd.timers.nixos-flake-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon *-*-1..7 03:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
