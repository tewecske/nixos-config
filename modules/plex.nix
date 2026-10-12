{ config, pkgs, ... }:

{
  # Writes to /mnt/externalwd (subtitles uploaded from the WebUI), so it joins `media`.
  users.users.plex.extraGroups = [ "media" ];

  # Plex - Media Server
  # http://localhost:32400
  services.plex = {
    enable = true;
    openFirewall = true;
  };

}
