# /etc/nixos/configuration.nix
# Cyberbee's NixOS System Configuration (Lenovo LOQ 15ARP9 / Pure NVIDIA / Hyprland)

{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
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
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

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
  # 2. BOOTLOADER, KERNEL & SYSTEM TUNING
  # =========================================================================
  boot = {
    kernelModules = [ "ideapad_laptop" ];
    consoleLogLevel = 0;
    initrd.verbose = false;

    # Silent boot & NVIDIA Wayland stability flags
    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
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
        # Manual prerequisite: theme installed via install.sh (CyberGRUB-2077) or placed at /boot/grub/themes/CyberGRUB-2077
        theme = "/boot/grub/themes/CyberGRUB-2077";
      };
    };
  };

  # =========================================================================
  # 3. NETWORKING, FIREWALL & LOCALIZATION
  # =========================================================================
  networking = {
    hostName = "cybees-nix";
    networkmanager.enable = true;
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

  # Background Network Daemons
  services.cloudflare-warp.enable = true;
  services.tailscale.enable = true;

  # =========================================================================
  # 4. HARDWARE, POWER & LAPTOP INTEGRATION
  # =========================================================================
  # NVIDIA Dedicated GPU Setup
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for 32-bit Proton & Wine gaming
  };

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = false; # Proprietary driver required for Wayland stability
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Bluetooth
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

  # Lenovo LOQ Battery Conservation Mode (80% charge threshold)
  systemd.services.lenovo-battery-conservation = {
    description = "Set Lenovo LOQ Battery Conservation Mode (80% Charge Limit)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = ''${pkgs.bash}/bin/bash -c "if [ -f /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode ]; then echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode; fi"'';
    };
  };

  # =========================================================================
  # 5. DESKTOP ENVIRONMENT, AUDIO & SECURITY
  # =========================================================================
  # SDDM Display Manager (X11 backend avoids Wayland DRM launch lockups)
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

  # =========================================================================
  # 6. GAMING, COMPATIBILITY & VIRTUALIZATION
  # =========================================================================
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  # Binary compatibility (precompiled binaries & CLI tooling)
  programs.nix-ld.enable = true;
  services.envfs.enable = true;

  # Containers
  virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = true;
    # dockerCompat = true;
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
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" "docker" ];
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

    # GUI & Productivity Applications
    vscode
    firefox
    discord
    cloudflare-warp

    # Multimedia, Graphics & Audio Production
    gimp
    blender
    easyeffects
    ffmpeg-full
    vlc
    ani-cli
    gpu-screen-recorder

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

    # Development: JavaScript / TypeScript
    nodejs_22
    bun
    pnpm
    yarn

    # Development: Python
    python3
    python3Packages.pip
    python3Packages.virtualenv

    # Development: Java Runtime
    jdk21
  ];

  # =========================================================================
  # 9. STATE VERSION
  # =========================================================================
  system.stateVersion = "26.05";
}