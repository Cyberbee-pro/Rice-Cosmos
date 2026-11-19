# nixos/configuration.nix
# Rice-Cosmos NixOS System Configuration (Hyprland + Caelestia Shell)

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

      trusted-users = [ "root" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Caelestia CLI Screen Recorder CPU Fallback Overlay
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
  # 2. BOOTLOADER & KERNEL
  # =========================================================================
  boot = {
    kernelModules = [ "uinput" ];

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
    hostName = "rice-cosmos";
    networkmanager = {
      enable = true;
      dns = "default";
    };
    firewall.enable = true;
  };

  # Set to your local timezone (e.g., "America/New_York", "Europe/London", "Europe/Paris")
  time.timeZone = "UTC";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
  ];

  # Cloudflare WARP Daemon
  services.cloudflare-warp.enable = true;

  # =========================================================================
  # 4. GRAPHICS, BLUETOOTH & POWER MANAGEMENT
  # =========================================================================
  hardware.uinput.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
    ];
  };

  # Optional: Uncomment if using a dedicated NVIDIA GPU
  # services.xserver.videoDrivers = [ "nvidia" ];
  # boot.kernelParams = [
  #   "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  #   "nvidia-drm.modeset=1"
  #   "nvidia-drm.fbdev=1"
  # ];
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   nvidiaPersistenced = true;
  #   powerManagement.enable = false;
  #   powerManagement.finegrained = false;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

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

  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # Storage & Automount Integration
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # =========================================================================
  # 5. DESKTOP ENVIRONMENT, AUDIO & SECURITY
  # =========================================================================
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
    autoNumlock = true;
  };

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

  systemd.user.services.xdg-desktop-portal.unitConfig = {
    Requisite = "";
    PartOf = "";
    BindsTo = "";
    After = "";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  security.polkit.enable = true;
  security.wrappers.gsr-kms-server = {
    source = "${pkgs.gpu-screen-recorder}/bin/gsr-kms-server";
    capabilities = "cap_sys_admin+ep";
    owner = "root";
    group = "root";
    permissions = "u+rx,g+rx,o+rx";
  };

  # =========================================================================
  # 6. BINARY COMPATIBILITY
  # =========================================================================
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      glib
      util-linux
    ];
  };
  services.envfs.enable = true;

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

  # CHANGE ME: Replace 'user' with your username and update the initial password
  users.users.user = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "input" ];
    initialPassword = "changeme";
    shell = pkgs.zsh;
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  # =========================================================================
  # 8. SYSTEM PACKAGES
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # Core CLI & Terminal Utilities
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
    psmisc
    playerctl
    bluez-tools
    lm_sensors
    libmtp

    # Networking
    cloudflare-warp

    # Wayland Desktop Shell, Screenshots & Appearance
    wl-clipboard
    grim
    slurp
    satty
    polkit_gnome
    copyq
    nwg-look
    caelestia-shell
    caelestia-cli
    gpu-screen-recorder

    # Cursor Themes
    bibata-cursors
    catppuccin-cursors.mochaDark
    nordzy-cursor-theme
    phinger-cursors

    # Default Desktop Apps & File Management
    firefox
    vlc
    ffmpeg-full
    gthumb
    kdePackages.dolphin
    kdePackages.ark
    kdePackages.kio-extras
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    kdePackages.qtimageformats
    kdePackages.ffmpegthumbs
    ffmpegthumbnailer

    # Graphics & Vulkan Utilities
    vulkan-tools
    mesa-demos
    libglvnd
  ];

  # =========================================================================
  # 9. STATE VERSION
  # =========================================================================
  system.stateVersion = "26.05";
}
