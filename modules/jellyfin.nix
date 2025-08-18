{ config, pkgs, ... }:

{
  users.groups.media.members = [
    "jellyfin"
  ];

  users.users.jellyfin.extraGroups = [ "media" "users" ];

  # Jellyfin media server
  # https://jellyfin.org/
  # http://localhost:8096
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
}