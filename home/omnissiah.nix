{ lib, pkgs, ... }:
{
  # omnissiah: the shared NixOS home config plus host-only extras.
  imports = [ ./nixos.nix ];

  home.sessionVariables.HM_TARGET = lib.mkForce "tewe@omnissiah";

  ### Playwright ###
  # Browsers come from nix (downloaded ones can't run on NixOS). The npm
  # `playwright` package version must match `playwright-driver` (see
  # `nix eval nixpkgs#playwright-driver.version`) or it looks for a
  # different browser revision.
  home.packages = [ pkgs.playwright-driver ];
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
