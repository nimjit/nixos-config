# This file is generated automatically by nixos-generate-config.
# Do not write it by hand.
#
# To generate it on a new machine:
#   nixos-generate-config --root /mnt
# Then copy /mnt/etc/nixos/hardware-configuration.nix here.
#
# The file below is a placeholder so the repo structure is valid.
# Replace it entirely with your generated version.

{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Replace everything below this line with your generated hardware-configuration.nix

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];  # use kvm-intel if Intel CPU
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-UUID";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-YOUR-BOOT-UUID";
    fsType = "vfat";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
