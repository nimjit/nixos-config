{ pkgs, ... }:

let
  nchat-monitor = pkgs.writeScript "nchat-unread-monitor" ''
    #!${pkgs.python3}/bin/python3
    import subprocess, re

    proc = subprocess.Popen(
        ['${pkgs.dbus}/bin/dbus-monitor', '--session',
         "type='method_call',interface='org.freedesktop.Notifications',member='Notify'"],
        stdout=subprocess.PIPE, text=True, bufsize=1
    )

    collecting = False
    for line in proc.stdout:
        line = line.strip()
        if 'member=Notify' in line:
            collecting = True
            continue
        if collecting:
            m = re.match(r'^string "(.*)"$', line)
            if m:
                if m.group(1) == 'nchat':
                    try:
                        count = int(open('/tmp/nchat-unread').read().strip())
                    except Exception:
                        count = 0
                    open('/tmp/nchat-unread', 'w').write(str(count + 1))
                collecting = False
  '';
in {
  home.file.".local/bin/nchat-unread-monitor" = {
    source     = nchat-monitor;
    executable = true;
  };

  systemd.user.services.nchat-unread-monitor = {
    Unit = {
      Description = "Count incoming nchat notifications";
      After        = [ "graphical-session.target" ];
      PartOf       = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${nchat-monitor}";
      Restart    = "always";
      RestartSec = "3";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
