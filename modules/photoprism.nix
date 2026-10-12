{ config, pkgs, ... }:

{
  users.groups.photoprism = { };
  users.groups.media.members = [
    "photoprism"
  ];

  users.users.photoprism = {
    isSystemUser = true;
    group = "photoprism";
    extraGroups = [ "media" ];
  };

  # Photoprism - Photo management and viewing
  # https://www.photoprism.app/
  # http://localhost:2342
  services.photoprism = {
    enable = true;
    port = 2342;
    originalsPath = "/mnt/externalwd/stuff/photos";
    storagePath = "/var/lib/photoprism";
    settings = {
      PHOTOPRISM_READONLY = "false";
      PHOTOPRISM_DISABLE_TLS = "true";
      PHOTOPRISM_DATABASE_DRIVER = "sqlite";
      # Login required. The admin account already exists, so set its password with
      # `sudo /var/lib/photoprism/photoprism-manage passwd admin` (not stored here).
      PHOTOPRISM_AUTH_MODE = "password";
      PHOTOPRISM_SITE_URL = "http://192.168.50.5:2342/";
      PHOTOPRISM_HTTP_HOST = "0.0.0.0";
      PHOTOPRISM_HTTP_PORT = "2342";
      PHOTOPRISM_JPEG_QUALITY = "70";
      PHOTOPRISM_JPEG_SIZE = "1920";
      PHOTOPRISM_THUMB_SIZE = "1920";
      PHOTOPRISM_THUMB_SIZE_UNCACHED = "1920";
    };
  };

  systemd.services.photoprism = {
    serviceConfig = {
      CPUQuota = "50%";
    };
  };

  # Open Photoprism port in firewall
  networking.firewall.allowedTCPPorts = [ 2342 ];
}
