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
    ../../modules/docker.nix

    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "omnissiah";

  # Keep the onboard Intel I219-V (eno1) armed for Wake-on-LAN, so a magic
  # packet can wake the box from S3 suspend, and from S5 poweroff as long as
  # the BIOS has "Wake on LAN / Power On by PCIe" enabled. Applied by udev
  # via a systemd .link file.
  networking.interfaces.eno1.wakeOnLan.enable = true;

  networking.networkmanager.enable = true;
  # Assumed same LAN as tewenixsrv — adjust if omnissiah lives elsewhere.
  networking.defaultGateway = "192.168.50.1";

  virtualisation.docker.enable = true;

  # Remote access from outside the LAN. One-time login: `sudo tailscale up`
  # (add `--ssh` for Tailscale SSH), then `ssh tewe@omnissiah` over the tailnet.
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Swap file on the ext4 root (no repartitioning needed). Sized for
  # hibernation: ~15.5 GiB RAM + headroom. To actually hibernate, also set
  # `boot.resumeDevice = "/dev/nvme0n1p2"` and the file's resume offset
  # (`boot.kernelParams = [ "resume_offset=<N>" ]`, N from
  # `sudo filefrag -v /swapfile`) *after* the file exists, i.e. after the
  # first rebuild below.
  swapDevices = [
    {
      device = "/swapfile";
      size = 20480; # MiB (20 GiB)
    }
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
