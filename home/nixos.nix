{ ... }:
{
  # NixOS. Nix is already present; only home-manager is layered on top.

  # Which homeConfiguration this machine is; read by the `hm` shell wrapper.
  home.sessionVariables.HM_TARGET = "tewe@nixos";

  # Host-only packages / settings go here.
}
