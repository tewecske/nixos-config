{ config, pkgs, ... }:

{
  users.groups.media.members = [
    "plex"
    "sonarr"
    "radarr"
  ];

  users.users.plex.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.radarr.extraGroups = [ "media" ];

  # Plex - Media Server
  # http://localhost:32400
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  # Open firewall for *arr services and qBittorrent
  networking.firewall.allowedTCPPorts = [
    8080   # qBittorrent
    8989   # Sonarr
    7878   # Radarr
    9696   # Prowlarr
    5055   # Overseerr
  ];
}
