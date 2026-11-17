
{
  nix = {
    settings = {
      substituters = [
        "https://ros.cachix.org"
      ];
      trusted-public-keys = [
        "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo="
      ];
    };
  };
}
