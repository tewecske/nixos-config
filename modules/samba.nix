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
        "guest account" = "nobody";
        "map to guest" = "bad user";
      };

      externalwd = {
        path = "/mnt/externalwd";
        browseable = true;
        "read only" = true;
        "guest ok" = true;
        "force user" = "nobody";
        "force group" = "nogroup";
      };
    };
  };
}
