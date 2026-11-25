# Lyrix — NixOS Homelab Configuration

Declarative NixOS configuration for **Lyrix**, an Intel N100-based homelab server.

This repository contains the complete NixOS Flake and Disko configuration used to install and manage the server.

## Hardware

| Component | Specification |
|---|---|
| System | Intel N100 mini PC |
| Architecture | x86_64 |
| RAM | 16 GB planned |
| Primary storage | 512 GB NVMe |
| Secondary storage | 4 TB WD external HDD |
| Hostname | `lyrix` |
| Operating system | NixOS 26.05 |

## Repository structure

```text
nixos-lyrix/
├── flake.nix
├── flake.lock
├── configuration.nix
├── hardware-configuration.nix
├── disko.nix
├── README.md
└── .gitignore
```

| File | Purpose |
|---|---|
| `flake.nix` | NixOS system definition and inputs |
| `flake.lock` | Pinned dependency versions |
| `configuration.nix` | Main system configuration |
| `hardware-configuration.nix` | Hardware-specific settings |
| `disko.nix` | NVMe partitioning and filesystem layout |
| `.gitignore` | Excludes generated build artifacts |

## Storage layout

### Primary NVMe

The 512 GB NVMe contains the NixOS installation:

- 1 GB EFI System Partition mounted at `/boot`
- Remaining space formatted as ext4 and mounted at `/`

**Warning:** Disko will erase and repartition the configured NVMe during installation.

### Secondary storage

The 4 TB external disk is formatted as Btrfs and mounted at `/storage/storage`
using UUID `95a2ad85-67e6-446a-9635-ae1c6fbd8bc4`.

It is intentionally excluded from `disko.nix`, so reinstalling NixOS does not
automatically repartition or format it.

Forgejo uses the existing storage layout:

- State and application data: `/storage/storage/git_storage/forgejo`
- Git repositories: `/storage/storage/git_storage/forgejo/repositories`
- Custom files: `/storage/storage/forgejo-app/custom`
- Backups: `/storage/storage/forgejo-app/dump`

At startup, a systemd service grants the Forgejo account read, write, and
traverse access to existing files on the mounted volume and default ACL access
for newly created content.

## Configuration features

- NixOS Flakes
- Disko declarative disk configuration
- systemd-boot
- NetworkManager
- OpenSSH
- SSH public-key and password authentication
- Root SSH password authentication
- Forgejo at `https://git.lyrexo.net`
- Docker
- Navidrome listening on `0.0.0.0:4533`
- Firewall disabled
- Persistent ZFS host ID
- Minimal, headless server environment
- `lyrexo` administrator account with sudo

Set the root password on the installed system with `passwd root` (or from
recovery with `nixos-enter --root /mnt -c 'passwd root'`). Password changes
persist across rebuilds. SSH password authentication is enabled for root and
regular users; use a strong password and prefer SSH keys when possible.

## Building

Build the system configuration from a Linux machine with Nix installed:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  build .#nixosConfigurations.lyrix.config.system.build.toplevel
```

## Deploying

Install or deploy the configuration using NixOS Anywhere:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  shell nixpkgs#nixos-anywhere nixpkgs#disko
```

Then:

```bash
nixos-anywhere --flake .#lyrix root@SERVER_IP
```

**Important:** Deployment is destructive to the NVMe specified in `disko.nix`. Verify the target disk identifier and back up important data before proceeding.

The existing 4 TB ZFS drive is not a Disko target.

## Updating the configuration

After modifying the configuration:

```bash
nix --extra-experimental-features 'nix-command flakes' \
  build .#nixosConfigurations.lyrix.config.system.build.toplevel
```

Commit and push changes:

```bash
git add .
git commit -m "Update Lyrix configuration"
git push
```

## Repository

[github.com/MaseDev33/homelab-nix-config](https://github.com/MaseDev33/homelab-nix-config)

---

Maintained as the declarative configuration for Lyrix.
