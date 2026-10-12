{ config, pkgs, ... }:

{
  # Writes to /mnt/externalwd (subtitles uploaded from the WebUI), so it joins `media`.
  users.users.jellyfin.extraGroups = [ "media" ];

  # Jellyfin media server
  # https://jellyfin.org/
  # http://localhost:8096
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
}
