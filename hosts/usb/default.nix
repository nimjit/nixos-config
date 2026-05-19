{ username, pkgs, ... }: {

  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "nixos-usb";

  # ── Bootloader ────────────────────────────────────────────────────────────
  # efiInstallAsRemovable is the critical setting for USB portability.
  # It writes the bootloader to /EFI/BOOT/BOOTX64.EFI (the universal fallback
  # path) instead of creating machine-specific NVRAM entries.
  # This makes the USB bootable on any machine regardless of its NVRAM state.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # Grub fallback in case systemd-boot doesn't work on a machine:
  # (uncomment if you have trouble booting on some hardware)
  # boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.grub.device = "nodev";

  # ── Broad hardware support ────────────────────────────────────────────────
  # These ensure the USB boots on a wide range of machines
  boot.initrd.availableKernelModules = [
    "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod"
    "rtsx_pci_sdmmc" "nvme" "uas"
  ];
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  # ── BACKUP partition ──────────────────────────────────────────────────────
  # The USB is partitioned so BACKUP lives on its own partition.
  # Mount it here; the actual UUID is filled in from hardware-configuration.nix
  # or manually after partitioning.
  fileSystems."/home/${username}/BACKUP" = {
    device = "/dev/disk/by-label/BACKUP";  # set label during partitioning
    fsType = "ext4";
    options = [ "defaults" "nofail" ];  # nofail: boot even if partition missing
  };

  # ── Desktop environment ───────────────────────────────────────────────────
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # ── Sound ─────────────────────────────────────────────────────────────────
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" ];
    initialPassword = "changeme";
  };

  system.stateVersion = "24.11";
}
