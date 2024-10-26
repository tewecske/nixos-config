{pkgs, ...}: {
 
  imports = [
    ../../home/core.nix
    ../../home/programs
    ../../home/shell
  ];

  programs.git = {
    userName = "tewe";
    userEmail = "leventewe@gmail.com";
  };
}
