{ ... }:
{
  # Per-project dev shells: a project's .envrc (`use flake`) loads its flake
  # devShell on cd and unloads it on leave. nix-direnv caches the shell and
  # pins it as a GC root, so `nix-collect-garbage` won't wipe it.
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };
}
