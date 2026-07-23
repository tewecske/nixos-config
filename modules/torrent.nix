{ pkgs, ... }:

let
  dataDir = "/var/lib/qbittorrent";
in
{

  users.users.radarr = {
    group = "users";
    isNormalUser = true;
    extraGroups = [ "media" ];
  };

  users.users.sonarr = {
    group = "users";
    isNormalUser = true;
    extraGroups = [ "media" ];
  };

  services.sonarr = {
    enable = true;
    user = "tewe";
    group = "users";
  };

  services.radarr = {
    enable = true;
    user = "tewe";
    group = "users";
  };

  services.prowlarr = {
    enable = true;
  };

  services.seerr = {
    enable = true;
  };

  systemd.services.qbittorrent = {
    description = "qbittorrent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    script = ''
      mkdir -p /home/tewe/.config/qbittorrent/qBittorrent/config
      ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080 --profile=/home/tewe/.config/qbittorrent
    '';
    serviceConfig.User = "tewe";
  };

  networking.firewall.allowedTCPPorts = [
    8080   # qBittorrent
    8989   # Sonarr
    7878   # Radarr
    9696   # Prowlarr
    5055   # Seerr
  ];
}

