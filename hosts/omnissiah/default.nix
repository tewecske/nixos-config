# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
#
# Same basic setup as tewenixsrv, minus the media stack (plex, jellyfin,
# sonarr/radarr/prowlarr/seerr/qbittorrent, photoprism) and the
# tewenixsrv-specific extras (cloudflared tunnel, samba share, gathedge app).

{ ... }:

{

  imports = [
    ../../modules/system.nix

    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "omnissiah";

  networking.networkmanager.enable = true;
  # Assumed same LAN as tewenixsrv — adjust if omnissiah lives elsewhere.
  networking.defaultGateway = "192.168.50.1";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
