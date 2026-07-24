{ config, pkgs, ... }:

{
  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "tewenixsrv";
        "netbios name" = "tewenixsrv";
        "security" = "user";
      };

      externalwd = {
        path = "/mnt/externalwd";
        browseable = true;
        "read only" = true;
        "valid users" = "tewe";
      };
    };
  };

  services.samba-wsdd.enable = true;
}

