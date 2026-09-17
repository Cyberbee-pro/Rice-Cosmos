{
  description = "Cyberbee's NixOS Flake Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    qylock = {
      url = "github:Darkkal44/qylock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprmod = {
      url = "github:BlueManCZ/hyprmod";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, qylock, hyprmod, ... }@inputs: {
    nixosConfigurations.cybees-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        qylock.nixosModules.default
        ({ pkgs, ... }: {
          programs.qylock = {
            enable = true;
            theme = "clockwork/orbital";
            themeOptions = {
              clockwork.orbital = {
                themeMode = "dark";
                enableWindup = true;
              };
            };
          };

          environment.systemPackages = [
            hyprmod.packages.x86_64-linux.default
          ];
        })
      ];
    };
  };
}
