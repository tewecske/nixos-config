{ ... }:
{
  # Bare-metal Ubuntu on aarch64 (e.g. Oracle Cloud Ampere).
  # Nix installed via the multi-user installer.
  # Host-only packages / settings go here.
  #
  # Shares home/common.nix with tewe@ubuntu; only the target name and the
  # build system (aarch64-linux, set in flake.nix) differ.

  # Which homeConfiguration this machine is; read by the `hm` shell wrapper.
  home.sessionVariables.HM_TARGET = "tewe@ubuntu-arm";
}
