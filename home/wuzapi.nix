{ pkgs, config, ... }:

let
  wuzapi = pkgs.buildGoModule {
    pname   = "wuzapi";
    version = "unstable-2025";
    src = pkgs.fetchFromGitHub {
      owner = "asternic";
      repo  = "wuzapi";
      rev   = "main";
      hash  = "sha256-OsLl8WOuCqPJ+C+YdXRqTTScopvD1M1VY4uMPYLzsFo=";
    };
    vendorHash = "sha256-nR7MwvGIJl1MGIZDGxE9vCoeUxzKpDGZn3fUEXECZ7I=";
    meta.mainProgram = "wuzapi";
  };

  dataDir = "${config.home.homeDirectory}/.local/share/wuzapi";
in {

  home.packages = [ wuzapi ];

  # wuzapi reads .env from its WorkingDirectory automatically.
  # Keys are in ~/.local/share/wuzapi/.env (moved from /var/lib/wuzapi/).
  systemd.user.services.wuzapi = {
    Unit = {
      Description = "wuzapi WhatsApp REST bridge";
      After       = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStart        = "${wuzapi}/bin/wuzapi -port 8089 -datadir ${dataDir} -logtype console";
      WorkingDirectory = dataDir;
      Restart          = "on-failure";
      RestartSec       = "5s";
    };
  };
}
