{
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: 
let
  cloudflared = pkgs-unstable.cloudflared;
  secrets = import ../secrets.nix;
in
{
  # cloudflared.packages = with nixpkgs-unstable; [
    # cloudflared
  # ];

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
      # ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=${secrets.cloudflared.nixpi4.token}";
      ExecStart = "${cloudflared}/bin/cloudflared tunnel --no-autoupdate run --token=${secrets.cloudflared.weecaldemo.token}";
      Group = "cloudflared";
      User = "cloudflared";
      Restart = "on-failure";
    };
  };

  # programs = {
    # cloudflared = {
      # enable = true;
    # };
  # };

}

