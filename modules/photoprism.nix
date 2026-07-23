{ config, pkgs, ... }:

{
  users.groups.media.members = [
    "photoprism"
  ];

  users.users.photoprism.extraGroups = [ "media" ];

  # Photoprism - Photo management and viewing
  # https://www.photoprism.app/
  # http://localhost:2342
  services.photoprism = {
    enable = true;
    port = 2342;
    originalsPath = "/mnt/externalwd/stuff/photos";
    storagePath = "/var/lib/photoprism";
    settings = {
      PHOTOPRISM_ADMIN_PASSWORD = "password";
      PHOTOPRISM_READONLY = false;
      PHOTOPRISM_DISABLE_TLS = true;
      PHOTOPRISM_DATABASE_DRIVER = "sqlite";
      PHOTOPRISM_AUTH_MODE = "public";
      PHOTOPRISM_SITE_URL = "http://192.168.50.5:2342/";
    };
  };

  systemd.services.photoprism = {
    serviceConfig = {
      SupplementaryGroups = [ "users" ];
    };
    after = [
      "mnt-externalwd.mount"
    ];
  };

  # Open Photoprism port in firewall
  networking.firewall.allowedTCPPorts = [ 2342 ];
}
