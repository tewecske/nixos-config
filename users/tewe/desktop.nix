{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    discord
    viber
    vlc
    google-chrome
    steam
  ];

  # programs.steam.enable = true;
  # programs.gamemode.enable = true;
  programs.firefox.enable = true;

}
