{
  lib,
  pkgs,
  pkgs-unstable,
  inputs,
  config,
  ...
}: 
let
  cloudflared = pkgs-unstable.cloudflared;
  common = {
    mode = "444";
    owner = "root";
    group = "root";
  };
in
{

  sops.secrets."cloudflared/weecaldemo/token" = {
    inherit (common) mode owner group;
  };

  users.users = {
    cloudflared = {
      group = "cloudflared";
      isSystemUser = true;
    };
  };
  users.groups.cloudflared = { };

  systemd.services.cloudflared = {
    after = [ "network.target" "network-online.target" ];
    wants = [ "network.target" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${cloudflared}/bin/cloudflared tunnel --no-autoupdate run";
      EnvironmentFile = "${config.sops.secrets."cloudflared/weecaldemo/token".path}";
      Group = "cloudflared";
      User = "cloudflared";
      Restart = "on-failure";
    };
  };

}

