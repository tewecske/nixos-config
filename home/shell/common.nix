{
  pkgs,
  ...
}:
# nix tooling
{
  home.packages = with pkgs; [
    # nixpkgs formatter
    alejandra
    # dead nix code
    deadnix
    # nix linter
    statix
  ];

  programs.direnv = {
    enable = true;
    # better direnv
    nix-direnv.enable = true;
    #enableZshIntegration = true;
  };
}
