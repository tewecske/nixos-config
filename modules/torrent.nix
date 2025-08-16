{ pkgs, ... }:

let
  dataDir = "/var/lib/qbittorrent";
in
{
  # services.bazarr = {
    # enable = true;
    # user = "tewe";
    # group = "users";
  # };
  services.sonarr = {
    enable = true;
    dataDir = "/home/tewe/.config/NzbDrone";
    user = "tewe";
    group = "users";
  };
  # services.prowlarr = {
    # enable = true;
    # dataDir = "/home/tewe/.config/Prowlerr";
    # user = "tewe";
    # group = "users";
  # };
  # services.jackett = {
    # enable = true;
    # dataDir = "/home/tewe/.config/jackett";
    # user = "tewe";
    # group = "users";
  # };
  services.radarr = {
    enable = true;
    dataDir = "/home/tewe/.config/Radarr";
    user = "tewe";
    group = "users";
  };

  # Also run qbittorrent-nox as svein.
  systemd.services.qbittorrent-sonarr = {
    description = "qbittorrent";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    script = ''
      mkdir -p /home/tewe/.config/qbittorrent/qBittorrent/config
      ${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --webui-port=8080 --profile=/home/tewe/.config/qbittorrent
    '';
    serviceConfig.User = "tewe";
  };
}

