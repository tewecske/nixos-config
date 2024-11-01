{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: {
  cloudflared.packages = with pkgs-unstable; [
    cloudflared
  ];

  # programs = {
    # cloudflared = {
      # enable = true;
    # };
  # };

}

