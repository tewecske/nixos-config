{ ... }:

{
  # Each service runs as its own system user (created by its NixOS module). The ones that
  # write to /mnt/externalwd join `media`, which owns that NTFS mount group-writable (see
  # hosts/tewenixsrv). Seerr and Prowlarr never touch the drive.
  users.users.qbittorrent.extraGroups = [ "media" ];
  users.users.sonarr.extraGroups = [ "media" ];
  users.users.radarr.extraGroups = [ "media" ];

  services.sonarr.enable = true;
  services.radarr.enable = true;
  services.prowlarr.enable = true;
  services.seerr.enable = true;

  # Profile in /var/lib/qBittorrent (module default). Settings stay in its own
  # qBittorrent.conf, managed from the WebUI (no serverConfig here).
  services.qbittorrent = {
    enable = true;
    webuiPort = 8080;
    torrentingPort = 20151;
  };

  networking.firewall.allowedTCPPorts = [
    8080 # qBittorrent
    20151 # qBittorrent peers
    8989 # Sonarr
    7878 # Radarr
    9696 # Prowlarr
    5055 # Seerr
  ];
  networking.firewall.allowedUDPPorts = [ 20151 ];
}
