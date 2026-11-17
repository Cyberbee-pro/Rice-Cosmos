# Cosmos Rice

![Full Banner](banner1.png)

A modular, distribution-agnostic automated deployment suite for custom Linux desktop environments. Designed for **Arch Linux** and **NixOS**, featuring animated terminal banners, custom dynamic ASCII art, Kitty terminal configurations, and system-level themes (CyberGRUB & SDDM).

---

## Features

* **Multi-Distribution Support**: Native package manager routing for Arch Linux (`pacman`) and NixOS / Nix (`nix profile`, flakes).
* **Interactive CLI Suite**: An interactive shell menu with truecolor ANSI gradients and smooth terminal animations.
* **Unified Hyprland & Dotfile Deployment**: Multi-app dotfile manager deploying unified Hyprland Lua, Kitty, Fastfetch, and Starship configurations with automated snapshot backups.
* **Live Configuration Harvester**: Easily sync live desktop changes back into the repository via `syncRepo.sh`.
* **Dynamic Fastfetch & Script Aliases**: Injects dynamic ASCII art banner, Starship prompt initialization, and automatic alias generation for Cosmos scripts into `.bashrc` and `.zshrc`.
* **System Theming & NixOS Deployment**:
  * **CyberGRUB-2077**: Automated setup of the Arasaka-styled GRUB bootloader theme.
  * **QYLock SDDM**: Modern SDDM login screen setup.
  * **Declarative NixOS Flake & Configs**: Automatic deployment of `./nixos/` flakes and modules to `/etc/nixos/` with machine hardware configuration preservation.
* **Idempotent & Safe**: Scripts can be run repeatedly without duplicating configuration entries or breaking active sessions.

---

## Project Structure

```text
├── ascii_arts/            # Custom ASCII banners for Fastfetch
├── configs/               # Dotfiles (hypr, kitty, fastfetch, starship)
│   ├── hypr/              # Unified hyprland.lua configuration
│   ├── kitty/             # Kitty terminal configuration
│   ├── fastfetch/         # Fastfetch configuration
│   └── starship/          # Starship prompt configuration
├── nixos/                 # Declarative NixOS system configurations & flakes
│   ├── assets/            # System wallpapers & assets
│   ├── cachix/            # Binary cache configurations
│   ├── Scripts/           # NixOS maintenance scripts (nix-cleanup, nix-rebuild)
│   ├── configuration.nix  # Master NixOS configuration
│   ├── flake.nix          # NixOS Flake definition
│   └── flake.lock         # Flake lockfile
├── Scripts/               # Companion deployment scripts
│   ├── download.sh        # Dependency & repository caching engine
│   ├── install.sh         # System themes, flakes & NixOS configuration deployer
│   ├── SrodKitty.sh       # Multi-app dotfile deployer & backup manager
│   ├── setShell.sh        # Dynamic Fastfetch banner, Starship & script alias injector
│   ├── syncRepo.sh        # Live system config harvester (System -> Repo)
│   └── syncWallpapers.sh  # Structured wallpaper deployer
├── Wallpapers/            # Curated wallpapers & dynamic animated backgrounds
└── main.sh                # Interactive master orchestrator
```

---

## Prerequisites

* **Arch Linux / Based Distros**: Ensure your user has `sudo` privileges and belongs to the `wheel` group.
* **NixOS / Nix**: Flakes and experimental features enabled:
```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];

```



---

## Installation & Usage

### 1. Clone the Repository

```bash
git clone https://github.com/Cyberbee-pro/Rice-Cosmos.git ~/CosmosRice
cd ~/CosmosRice

```

### 2. Grant Permissions

```bash
chmod +x main.sh Scripts/*.sh

```

### 3. Launch the Master Suite

```bash
./main.sh

```

---

## Interactive Menu Options

```text
  [1] Run Full Pipeline              (Execute all stages sequentially)
  [2] Switch Target OS (ARCH / NIX)  (Toggle between Arch and NixOS)
  [3] Download Assets                (Git, Kitty, Fastfetch, Theme Repos)
  [4] Install Themes & Shell         (Caelestia, SDDM, GRUB, Flake)
  [5] Deploy Dotfiles                (Hyprland, Kitty, Fastfetch, Starship)
  [6] Configure Shell & Aliases      (Fastfetch Banner & Script Aliases)
  [7] Sync Wallpapers (Structured)   (Deploy hierarchy to ~/Pictures/Wallpapers)
  [8] Harvest Live Configs -> Repo   (Live System Configs -> configs/)
  [0] Exit
```

---

## Post-Installation

After running the full pipeline or individual modules, restart your shell to apply changes:

```bash
exec $SHELL

```

---

## License

This project is open-source and available under the [MIT License](LICENSE).