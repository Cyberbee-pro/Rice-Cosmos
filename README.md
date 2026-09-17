# Cosmos Rice

![Full Banner](banner1.png)

A modular, distribution-agnostic automated deployment suite for custom Linux desktop environments. Designed for **Arch Linux** and **NixOS**, featuring animated terminal banners, custom dynamic ASCII art, Kitty terminal configurations, and system-level themes (CyberGRUB & SDDM).

---

## Features

* **Multi-Distribution Support**: Native package manager routing for Arch Linux (`pacman`) and NixOS / Nix (`nix profile`, flakes).
* **Interactive CLI Suite**: An interactive shell menu with truecolor ANSI gradients and smooth terminal animations.
* **Dynamic Fastfetch Banners**: Randomly rotates custom ASCII art on terminal launch via shell integration (`.bashrc` / `.zshrc`).
* **Kitty Terminal Configuration**: Automated deployment of Kitty presets with automated snapshot backups for existing configurations.
* **System Theming**:
* **CyberGRUB-2077**: Automated setup of the Arasaka-styled GRUB bootloader theme.
* **QYLock SDDM**: Modern SDDM login screen setup.
* **Declarative Nix Support**: Generates ready-to-import Nix modules (`nixos-theme-module.nix`) on NixOS systems.


* **Idempotent & Safe**: Scripts can be run repeatedly without duplicating configuration entries or breaking active sessions.

---

## Project Structure

```text
├── ascii_arts/            # Custom ASCII banners for Fastfetch
├── configs/               # Dotfiles (kitty, fastfetch, starship)
├── Wallpapers/            # Curated wallpapers & dynamic animated backgrounds
├── nixos/                 # Declarative NixOS system configurations
├── download.sh            # Dependency & repository caching engine
├── install.sh             # System themes & shell installation script
├── SrodKitty.sh           # Kitty dotfile deployer & backup manager
├── setShell.sh            # Shell integration & dynamic ASCII configurator
├── syncWallpapers.sh      # Structured wallpaper deployer
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
chmod +x main.sh download.sh install.sh SrodKitty.sh setShell.sh syncWallpapers.sh

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
  [4] Install Themes & Shell         (Caelestia, SDDM, GRUB)
  [5] Deploy Kitty Config            (Kitty terminal dotfile sync & backup)
  [6] Configure ASCII Art & Shell    (Fastfetch shell banner injection)
  [7] Sync Wallpapers (Structured)   (Deploy hierarchy to ~/Pictures/Wallpapers)
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