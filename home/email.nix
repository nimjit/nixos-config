{ ... }: {

  # Thunderbird is installed via common.nix.
  # Account setup is done through the GUI the first time — there is no
  # declarative way to store email passwords in Nix (nor should there be).
  #
  # To connect to Outlook/Microsoft 365:
  # 1. Open Thunderbird
  # 2. Add account → enter your email
  # 3. Thunderbird auto-detects Microsoft's IMAP settings
  # 4. Authenticate via OAuth (browser popup) — no app password needed
  #
  # For university email (often Exchange):
  # Server: outlook.office365.com
  # Port: 993 (IMAP), SSL/TLS
  # Authentication: OAuth2

  # Profile and account data are stored in ~/.thunderbird/
  # To sync this across machines, add the profile folder to your BACKUP
  # sync in syncthing.nix and symlink it:

  # home.file.".thunderbird".source =
  #   config.lib.file.mkOutOfStoreSymlink
  #   "/home/yourname/BACKUP/thunderbird-profile";

  # Uncomment the above two lines after your first Thunderbird setup,
  # and move ~/.thunderbird to BACKUP/thunderbird-profile first.
}
