{
  lib,
  pkgs,
  system,
  opencode,
  ...
}:
{
  # omnissiah: the shared NixOS home config plus host-only extras.
  imports = [ ./nixos.nix ];

  home.sessionVariables.HM_TARGET = lib.mkForce "tewe@omnissiah";

  ### Playwright ###
  # Browsers come from nix (downloaded ones can't run on NixOS). The npm
  # `playwright` package version must match `playwright-driver` (see
  # `nix eval nixpkgs#playwright-driver.version`) or it looks for a
  # different browser revision.
  #
  # opencode: anomalyco/opencode v2 branch flake, not yet on nixpkgs.
  # omnissiah only — see `opencode` input in flake.nix. Shell-completion
  # generation in their postInstall shells out to `opencode completion`,
  # which chdir's into packages/cli/completion — a dir missing from this
  # checkout (upstream v2 packaging bug, not ours to fix). Drop that phase;
  # we don't need bash/zsh completions.
  home.packages = [
    pkgs.playwright-driver
    (opencode.packages.${system}.default.overrideAttrs (_: {
      postInstall = "";
    }))
  ];
  home.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
