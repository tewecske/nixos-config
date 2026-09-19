# Shared Docker defaults. Import this module, then enable per host with the
# native `virtualisation.docker.enable = true;` (see hosts/omnissiah).
# Any `virtualisation.docker.*` option can be overridden per host.
{
  config,
  lib,
  username,
  ...
}:

{
  config = lib.mkIf config.virtualisation.docker.enable {
    virtualisation.docker.autoPrune = {
      enable = lib.mkDefault true;
      dates = lib.mkDefault "weekly";
    };

    users.users.${username}.extraGroups = [ "docker" ];
  };
}
