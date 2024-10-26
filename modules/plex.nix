{ config, pkgs, ... }:

{
  users.groups.media.members = [
    "plex"
  ];

  users.users.plex.extraGroups = [ "media" ];

  # Plex
  # https://plex.tv/
  # http://localhost:32400 
  services.plex = {
    enable = true;
    openFirewall = true;
  };
}
