# Module from the lazyenv flake input (see flake.nix); settings -> config.toml.
{ ... }:
{
  programs.lazyenv = {
    enable = true;
  };
}
