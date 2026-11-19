# Cosmo CLI - V2

![Full Banner](banner1.png)

A modular, distribution-agnostic automated deployment suite for custom Linux desktop environments. Designed for **Arch Linux** and **NixOS**, featuring animated terminal banners, custom dynamic ASCII art, Kitty terminal configurations, and system-level themes (CyberGRUB & SDDM).

---

## Features

* **Multi-Distribution Support**: Native package manager routing for Arch Linux (`pacman`, AUR helper) and NixOS / Nix (`nixos-rebuild`, flakes).
* **Interactive CLI Suite**: An interactive shell menu with truecolor ANSI gradients and smooth terminal animations.
* **Unified Desktop & Dotfile Deployment**: Multi-app configuration and helper script manager deploying Caelestia Shell (with Hyprland Lua API overrides), Neovim, Kitty, Fastfetch, and Starship configurations with automated snapshot backups and helper scripts (`gamemode.sh`, `toggle-hz.sh`, `toggle-opacity.sh`) to `~/.local/bin/`.
* **Dynamic Fastfetch & Script Aliases**: Injects dynamic ASCII art banner, Starship prompt initialization, and automatic alias generation (`cosmo`, `cosmos`, and companion scripts) into `.bashrc` and `.zshrc`.
* **System Theming & NixOS Deployment**:
  * **CyberGRUB-2077**: Automated setup of the Arasaka-styled GRUB bootloader theme.
  * **QYLock SDDM**: Modern SDDM login screen setup featuring the NieR:Automata theme on Arch Linux and NixOS.
  * **Declarative NixOS Flake & Configs**: Automatic deployment of `./nixos/` flakes and modules to `/etc/nixos/` with machine hardware configuration preservation.
* **Idempotent & Safe**: Scripts can be run repeatedly without duplicating configuration entries or breaking active sessions.

---

## Project Structure

```text
├── ascii_arts/            # Custom ASCII banners for Fastfetch
├── configs/               # Dotfiles (caelestia, fastfetch, kitty, nvim, starship)
│   ├── caelestia/         # Caelestia shell configuration & hypr Lua overrides
│   ├── fastfetch/         # Fastfetch configuration
│   ├── kitty/             # Kitty terminal configuration
│   ├── nvim/              # Neovim configuration (Lazy.nvim)
│   └── starship/          # Starship prompt configuration
├── nixos/                 # Declarative NixOS system configurations & flakes
│   ├── assets/            # System wallpapers & assets
│   ├── Scripts/           # NixOS maintenance scripts (nix-cleanup, nix-rebuild)
│   ├── configuration.nix  # Master NixOS configuration
│   ├── flake.nix          # NixOS Flake definition
│   ├── flake.lock         # Flake lockfile
│   └── hardware-configuration.nix # Template hardware stub
├── Scripts/               # Modular companion deployment scripts
│   ├── bin/               # Helper utilities deployed to ~/.local/bin (gamemode, toggle-hz, toggle-opacity)
│   ├── download.sh        # Dependency & repository caching engine
│   ├── install.sh         # System themes, flakes & NixOS configuration deployer
│   ├── SrodKitty.sh       # Multi-app dotfile deployer & backup manager
│   ├── setShell.sh        # Shell environment orchestrator
│   ├── setup-bash.sh      # Standalone Bash, banner & alias injector
│   ├── setup-zsh.sh       # Standalone Zsh, banner & alias injector
│   ├── setup-kitty.sh     # Standalone Kitty terminal deployer
│   ├── setup-starship.sh  # Standalone Starship prompt configurator
│   ├── setup-fastfetch.sh # Standalone Fastfetch configurator
│   ├── setup-caelestia.sh # Standalone Caelestia shell deployer
│   ├── setup-hypr.sh      # Standalone Hyprland runtime packages installer
│   ├── setup-nvim.sh      # Standalone Neovim deployer
│   ├── setup-bin.sh       # Standalone helper binaries deployer
│   ├── setup-sddm.sh      # Standalone SDDM & QYLock deployer
│   ├── syncRepo.sh        # Live configuration harvester (system -> repo)
│   └── syncWallpapers.sh  # Structured wallpaper deployer
├── Wallpapers/            # Curated wallpapers & dynamic animated backgrounds
└── main.sh                # Interactive master orchestrator (Cosmo CLI)
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
git clone https://github.com/Cyberbee-pro/Cosmo-CLI.git ~/Cosmo-CLI
cd ~/Cosmo-CLI
```

> **Note:** If you previously cloned from `https://github.com/Cyberbee-pro/Rice-Cosmos.git` or have an existing `~/CosmosRice` checkout, Cosmo CLI retains full backward compatibility with your existing environment.

### 2. Grant Permissions

```bash
chmod +x main.sh Scripts/*.sh
```

### 3. Launch the Master Suite

```bash
./main.sh
```

Or, once your shell is configured, simply run:
```bash
cosmo
# or
cosmos
```

---

## Interactive Menu Options

```text
  [1] Full Pipeline (ARCH / NIX)     (Execute all stages sequentially)
  [2] Switch Target OS (ARCH / NIX)  (Toggle between Arch Linux and NixOS)
  [3] Terminal-Only Setup            (Standalone Bash + Kitty)
  [4] Modular Component Setups       (Individual per-component setups)
  [5] Download Packages & Assets     (Core packages, AUR helper & themes)
  [6] Install Themes / NixOS Flake   (SDDM / CyberGRUB / /etc/nixos flake)
  [7] Deploy Dotfiles & Binaries     (Multi-app dotfile orchestration)
  [8] Configure Shells & Aliases     (Bash & Zsh banner & aliases)
  [9] Sync Wallpapers (Structured)   (Deploy hierarchy to ~/Pictures/Wallpapers)
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
