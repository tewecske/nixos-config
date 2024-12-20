# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, pkgs-unstable, ... }:

{
  imports =
    [
      ../../modules/system.nix
      # ../../modules/i3.nix
      ../../modules/plex.nix
      ../../modules/torrent.nix
      ../../modules/cloudflared.nix

      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "ntfs" ];

  systemd.services.plex = {
    serviceConfig = {
      SupplementaryGroups = [ "users" ];  # Add Plex to users group
    };
    after = [
      "mnt-externalwd.mount"
    ];
  };

  # systemd.services.hd-idle = {
    # description = "External HD spin down daemon";
    # wantedBy = [ "multi-user.target" ];
    # serviceConfig = {
      # Type = "forking";
      # ExecStart = "${pkgs.hd-idle}/bin/hd-idle -i 0 -a sdb -i 600";
    # };
  # };

  networking.hostName = "tewenixsrv"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  networking.defaultGateway = "192.168.50.1";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

}


