# nixos-config

My NixOS system configuration. Manages all machines declaratively — packages,
theming, dotfiles, and services — from a single repo.

---

## Machines

| Hostname | Description |
|---|---|
| `nixos-desktop` | Main desktop |
| `nixos-laptop` | Laptop |
| `nixos-usb` | Portable USB install |

---

## First-Time Setup

### Step 1 — Before anything: put your colour values in `themes/ukiyo.nix`

Open your current Obsidian theme CSS on your existing machine. Find the colour
variables and map them to the base16 slots in `themes/ukiyo.nix`. The comments
in that file explain what each slot is for.

Also add a wallpaper image to `themes/wallpapers/` and update the path in
`modules/stylix.nix`.

### Step 2 — Download the NixOS ISO and write it to USB

On your Ubuntu system (or any Linux machine):

```bash
# Download the minimal ISO
wget https://channels.nixos.org/nixos-unstable/latest-nixos-minimal-x86_64-linux.iso

# Find your USB device name (look for your USB size)
lsblk

# Write the ISO (replace sdX with your actual device, e.g. sdb — NOT sdb1)
sudo dd if=latest-nixos-minimal-x86_64-linux.iso of=/dev/sdX bs=4M status=progress
sync
```

### Step 3 — Set up this repo on GitHub

On your Ubuntu system, before booting NixOS:

```bash
# Install git if not present
sudo apt install git

# Clone this repo or create a new one
git clone https://github.com/YOURUSERNAME/nixos-config
# or: initialise from scratch and push

# Edit flake.nix and home/default.nix: replace "yourname" with your username
# Edit home/default.nix: set your git name and email
# Edit themes/ukiyo.nix: fill in your colours
# Add your userChrome.css content to home/dotfiles/userChrome.css
# Add your existing init.vim content to home/dotfiles/neovim/init.vim

git add .
git commit -m "initial config"
git push
```

### Step 4 — Partition and install (desktop or laptop)

Boot from the NixOS USB. You will land in a shell as root.

**Connect to internet first:**
```bash
# For ethernet: should work automatically
# For WiFi:
iwctl
  device list
  station wlan0 scan
  station wlan0 get-networks
  station wlan0 connect "YourNetworkName"
  exit
```

**Partition the disk (UEFI, replaces entire disk):**
```bash
# Find your disk
lsblk
# It will be something like nvme0n1 or sda

# Partition (replace nvme0n1 with your disk)
parted /dev/nvme0n1 -- mklabel gpt
parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 512MiB
parted /dev/nvme0n1 -- mkpart primary ext4 512MiB 100%
parted /dev/nvme0n1 -- set 1 esp on

# Format
mkfs.fat -F 32 /dev/nvme0n1p1
mkfs.ext4 -L nixos /dev/nvme0n1p2

# Mount
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

**Generate hardware config:**
```bash
nixos-generate-config --root /mnt
```

Copy the generated hardware-configuration.nix to a USB stick or note the
UUIDs, then update `hosts/desktop/hardware-configuration.nix` (or laptop)
in this repo with those values. Push the update from another machine, or
edit in-place on the mounted NixOS drive.

**Install from this repo:**
```bash
# Install git in the live environment
nix-env -iA nixos.git

# Clone your config
git clone https://github.com/YOURUSERNAME/nixos-config /mnt/etc/nixos

# Replace the placeholder hardware-configuration.nix with the generated one
cp /mnt/etc/nixos/generated-hardware.nix /mnt/etc/nixos/hosts/desktop/hardware-configuration.nix

# Install (replace "desktop" with your hostname target)
nixos-install --flake /mnt/etc/nixos#desktop

# Set root password when prompted
# Reboot
reboot
```

### Step 5 — After first boot

```bash
# Change your user password (initial is "changeme")
passwd

# Authenticate Tailscale
sudo tailscale up

# Clone the config to /etc/nixos for the auto-update service
sudo git clone https://github.com/YOURUSERNAME/nixos-config /etc/nixos

# Verify the system is healthy
systemctl --failed
journalctl -u nixos-health
```

### Step 6 — Set up Syncthing

1. Open a browser and go to `http://localhost:8384`
2. Note your device ID (Actions → Show ID)
3. Add it to `modules/syncthing.nix` under `devices`
4. Do the same on each other device
5. Set the `devices` list in the `BACKUP` folder entry
6. Commit and push; rebuild: `rebuild`

---

## USB Install (Portable)

### Partition the USB differently (3 partitions)

```bash
# The USB needs: EFI + root + BACKUP data partition
parted /dev/sdX -- mklabel gpt
parted /dev/sdX -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sdX -- mkpart primary ext4 512MiB 44GiB   # ~40GB for NixOS
parted /dev/sdX -- mkpart primary ext4 44GiB 100%     # remaining for BACKUP
parted /dev/sdX -- set 1 esp on

mkfs.fat -F 32 /dev/sdX1
mkfs.ext4 -L nixos /dev/sdX2
mkfs.ext4 -L BACKUP /dev/sdX3

mount /dev/sdX2 /mnt
mkdir -p /mnt/boot
mount /dev/sdX1 /mnt/boot
```

Then install with `--flake .#usb` instead of `#desktop`.

The BACKUP partition is mounted automatically at `/home/yourname/BACKUP` by
`hosts/usb/default.nix` via the `BACKUP` label.

---

## Daily Workflow

```bash
# Apply config changes
rebuild

# Pull from GitHub and rebuild
update

# Check system health
journalctl -u nixos-health

# Roll back last change
sudo nixos-rebuild switch --rollback

# Update all flake inputs (monthly)
cd /etc/nixos && sudo nix flake update && rebuild

# Clean old generations
gc
```

---

## Adding a New Package

1. Find it at https://search.nixos.org/packages
2. Add to `environment.systemPackages` in `modules/common.nix`
3. `git commit -m "add package" && git push`
4. `rebuild`

---

## Switching Themes

1. Add a new palette file to `themes/` (copy `ukiyo.nix` as a template)
2. Change `base16Scheme` in `modules/stylix.nix` to point at the new file
3. `rebuild` — the entire system recolours itself
