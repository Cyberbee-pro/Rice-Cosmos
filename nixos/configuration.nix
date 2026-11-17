# /etc/nixos/configuration.nix
# Cyberbee's NixOS System Configuration (Lenovo LOQ 15ARP9 / Pure NVIDIA / Hyprland)

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./cachix.nix
  ];

  # =========================================================================
  # 1. NIX DAEMON, FLAKES & STORE OPTIMIZATION
  # =========================================================================
  nixpkgs.config.allowUnfree = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      connect-timeout = 5;
      download-buffer-size = 67108864; # 64MB buffer

      # Trusted Users & ROS 2 Cachix Binary Cache
      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://ros.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "ros.cachix.org-1:dSyZx3Wmy2A34A3myy4BaCeDRhx8WfMq2GYLBy3LuNE="
      ];
      # To configure GitHub access tokens securely without committing credentials,
      # provide a secret file and reference it via:
      # nix.extraOptions = "!include /run/secrets/nix-access-tokens";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Caelestia Shell & CLI Overlays
  nixpkgs.overlays = [
    (final: prev: {
      caelestia-cli = prev.caelestia-cli.overrideAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace src/caelestia/subcommands/record.py \
            --replace-fail '[RECORDER' '[RECORDER, "-fallback-cpu-encoding", "yes"'
        '';
      });
    })
  ];

  # =========================================================================
  # 2. BOOTLOADER, KERNEL & SYSTEM TUNING (ARCH-STYLE QUIET BOOT)
  # =========================================================================
  boot = {
    # Added xpad and uinput for Xbox controller rumble and user-space input mapping
    kernelModules = [ "ideapad_laptop" "xpad" "uinput" ];
    consoleLogLevel = 0;
    initrd.verbose = false;

    # Hardware quirks for external USB bridge stability
    extraModprobeConfig = ''
      options usb-storage quirks=14cd:6116:u
    '';

    # Arch-style silent kernel output & NVIDIA DRM parameters
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "vt.global_cursor_default=0"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "acpi_backlight=native"
    ];

    # Force IPv4 routing to bypass slow/broken IPv6 routes
    kernel.sysctl = {
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
    };

    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        efiSupport = true;
        devices = [ "nodev" ];
        theme = "/boot/grub/themes/CyberGRUB-2077";
        configurationLimit = 10;
      };
    };
  };

  # =========================================================================
  # 3. NETWORKING, FIREWALL & LOCALIZATION
  # =========================================================================
  networking = {
    hostName = "cybees-nix";
    networkmanager = {
      enable = true;
      dns = "default";
    };
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 41641 ];
      checkReversePath = "loose";
    };
  };

  time.timeZone = "Asia/Kolkata";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];

  # Background Network Daemons
  services.cloudflare-warp.enable = true;
  services.tailscale.enable = true;

  # =========================================================================
  # 4. HARDWARE, POWER & LAPTOP INTEGRATION
  # =========================================================================
  # Enable userland uinput access and Steam controller udev rules for force feedback
  hardware.uinput.enable = true;
  hardware.steam-hardware.enable = true;

  # Hardware Graphics (Mesa / Vulkan Drivers)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

  # Enable X11 server for SDDM display manager integration
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # NVIDIA Dedicated GPU Setup (LOQ 15ARP9 - dGPU Only pinned to legacy 580)
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaPersistenced = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    
    # Official NVIDIA driver package
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bluetooth Configuration
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        FastConnectable = true;
        JustWorksRepairing = "always";
      };
      Policy = {
        AutoEnable = true;
      };
    };
  };

  # Power & Battery Services
  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Lenovo LOQ Battery Conservation Mode (Set to 0 for 100% full charge)
  systemd.services.lenovo-battery-conservation = {
    description = "Disable Lenovo LOQ Battery Conservation Mode (Full 100% Charge)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''${pkgs.bash}/bin/bash -c "if [ -f /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode ]; then echo 0 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode; fi"'';
    };
  };

  # Storage Integration
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # =========================================================================
  # 5. DESKTOP ENVIRONMENT, AUDIO & SECURITY
  # =========================================================================
  # SDDM Display Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    autoNumlock = true;
  };

  # Hyprland Compositor & Portals
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    configPackages = [ pkgs.hyprland ];
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  # Override xdg-desktop-portal dependency checks to allow startup under SDDM
  systemd.user.services.xdg-desktop-portal.unitConfig = {
    Requisite = "";
    PartOf = "";
    BindsTo = "";
    After = "";
  };

  # Audio Subsystem
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Privilege Management & Hardening Wrappers
  security.polkit.enable = true;
  security.wrappers.gsr-kms-server = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+rx,o+rx";
  };

  # PostgreSQL Database Server
  services.postgresql = {
    enable = true;
    ensureDatabases = [ "devdb" ];
    ensureUsers = [
      {
        name = "cyberbee";
        ensureClauses.superuser = true;
      }
    ];
  };

  # =========================================================================
  # 6. GAMING, COMPATIBILITY & VIRTUALIZATION
  # =========================================================================
  services.flatpak.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
    package = pkgs.steam.override {
      extraArgs = "-cef-enable-debugging";
    };
  };

  programs.gamemode.enable = true;

  # Binary compatibility
  # Binary compatibility
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib # Provides libstdc++.so.6
      zlib             # Common dependency for LSPs
      openssl
      curl
      glib
      util-linux
    ];
  };
  services.envfs.enable = true;

  # Containers
  virtualisation.docker = {
    enable = true;
    enableOnBoot = false;
    autoPrune.enable = true;
  };
  virtualisation.podman = {
    enable = true;
  };

  # =========================================================================
  # 7. USERS & ENVIRONMENT
  # =========================================================================
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  programs.starship.enable = true;
  programs.firefox.enable = true;

  users.users.cyberbee = {
    isNormalUser = true;
    description = "Limited Probabilities Infinite Possibilities";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "docker" "adbusers" ];
    initialPassword = "nixos";
    shell = pkgs.zsh;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Wayland native mode for Chromium/Electron apps
  };

  # =========================================================================
  # 8. SYSTEM PACKAGES
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # Core CLI Tools & Terminal Navigation
    vim
    neovim
    git
    curl
    wget
    kitty
    fastfetch
    ripgrep
    fd
    fzf
    tree
    jq
    pciutils
    usbutils
    brightnessctl
    libnotify
    yazi
    zoxide
    steam-run
    nix-output-monitor
    psmisc
    distrobox
    playerctl
    bluez-tools
    gthumb
    android-tools
    lm_sensors
    evtest # Useful CLI utility for verifying input & force feedback events

    # MTP & Storage Tools
    libmtp
    android-file-transfer

    # GUI & Productivity Applications
    vscode
    firefox
    discord
    obsidian
    cloudflare-warp

    # Multimedia, Graphics & Audio Production
    gimp
    blender
    easyeffects
    ffmpeg-full
    vlc
    ani-cli
    gpu-screen-recorder

    # Graphics Backend, Diagnostic Tools & NVML Monitoring
    vulkan-tools
    mesa-demos
    libglvnd
    nvtopPackages.nvidia

    # Direct NVIDIA utilities bin for Caelestia sysfs reader fallback
    config.boot.kernelPackages.nvidiaPackages.legacy_580.bin
    config.boot.kernelPackages.nvidiaPackages.legacy_580.settings

    # Wayland Desktop Shell, Screenshotting & Look/Feel
    wl-clipboard
    grim
    slurp
    polkit_gnome
    copyq
    nwg-look
    caelestia-shell
    caelestia-cli

    # Cursor Themes
    bibata-cursors
    catppuccin-cursors.mochaDark
    nordzy-cursor-theme
    phinger-cursors

    # KDE Apps, Dolphin & Thumbnailing Framework
    kdePackages.kdenlive
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kio-extras
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    kdePackages.qtimageformats
    kdePackages.kdesdk-thumbnailers
    kdePackages.taglib
    kdePackages.ffmpegthumbs
    ffmpegthumbnailer

    # Development: C / C++
    gcc
    gnumake
    cmake
    gdb
    pkg-config
    sqlite
    mariadb
    postgresql
    nil
    asm-lsp
    cargo
    rustc
    clang-tools
    gh

    # Development: JavaScript / TypeScript
    nodejs_22
    bun
    pnpm
    yarn

    # Development: Python
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Gaming & Compatibility Utilities
    protontricks
    pulseaudio

    # Development: Java Runtime
    jdk21
  ];

  # =========================================================================
  # 9. STATE VERSION
  # =========================================================================
  system.stateVersion = "26.05";
}
