# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Services that use /mnt/externalwd. ntfs3 stores the creator's owner and mode on every
  # file it creates, overriding the mount's gid/masks, so new files must come out right:
  # group `media` (inherited from the setgid directories) and group-writable.
  externalwd = {
    requires = [ "mnt-externalwd.mount" ];
    after = [ "mnt-externalwd.mount" ];
    serviceConfig.UMask = lib.mkForce "0007";
  };
in

{

  imports = [
    ../../modules/system.nix
    ../../modules/plex.nix
    ../../modules/jellyfin.nix
    ../../modules/torrent.nix
    ../../modules/cloudflared.nix
    ../../modules/photoprism.nix
    ../../modules/samba.nix
    ../../modules/gathedge.nix
    ../../modules/monitoring.nix

    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.supportedFilesystems = [ "ntfs" ];

  # usb1-port13 / usb2-port7 report a bogus over-current on this board. With
  # nothing attached, the USB2 root hub loops on runtime autosuspend (aborted
  # by the over-current flag), pinning a CPU in kworker/ksoftirqd. Keep it on.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", KERNEL=="usb1", ATTR{power/control}="on"
  '';

  # Push to ntfy.sh when any USB port's over_current_count rises. A steadily
  # climbing count means something really draws current; one blip at boot is
  # the known fault. Subscribe to the topic in `secrets.yaml` (ntfy_topic).
  sops.secrets.ntfy_topic = { };

  systemd.services.usb-overcurrent-alert = {
    description = "Alert on USB over-current count increase";
    path = with pkgs; [
      curl
      coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "usb-overcurrent-alert";
      LoadCredential = "topic:${config.sops.secrets.ntfy_topic.path}";
    };
    script = ''
      state=/var/lib/usb-overcurrent-alert/last
      boot=$(cat /proc/sys/kernel/random/boot_id)
      cur=""
      for f in /sys/bus/usb/devices/usb*/*/usb*-port*/over_current_count; do
        cur+="$(basename "$(dirname "$f")")=$(cat "$f") "
      done

      # Kernel counters reset on reboot: compare only within one boot.
      lastboot="" last=""
      [ -f "$state" ] && { read -r lastboot; read -r last; } < "$state"
      [ "$lastboot" = "$boot" ] || last=""

      changed=""
      for kv in $cur; do
        port=''${kv%=*} n=''${kv#*=} prev=0
        for old in $last; do [ "''${old%=*}" = "$port" ] && prev=''${old#*=}; done
        [ "$n" -gt "$prev" ] && changed+="$port: $prev -> $n"$'\n'
      done
      printf '%s\n%s\n' "$boot" "$cur" > "$state"

      if [ -n "$changed" ]; then
        curl -fsS --retry 3 \
          -H "Title: tewenixsrv USB over-current" -H "Priority: high" -H "Tags: warning" \
          -d "$changed(counts since last boot)" \
          "https://ntfy.sh/$(cat "$CREDENTIALS_DIRECTORY/topic")"
      fi
    '';
  };

  systemd.timers.usb-overcurrent-alert = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "5min";
    };
  };

  # Writers to /mnt/externalwd (members come from the service modules). Pinned because the
  # mount option needs the number; 993 is what it was already allocated.
  users.groups.media.gid = 993;
  users.users.tewe.extraGroups = [ "media" ];

  # externalwd (NTFS) refuses to mount at boot when its dirty flag is set, e.g. after a power
  # cut. Without the mount these services would run against the empty /mnt/externalwd on the
  # root disk (qBittorrent downloading there, libraries looking empty), so they require it and
  # stay down instead. After fixing/mounting it by hand, start them:
  #   sudo systemctl start qbittorrent plex jellyfin photoprism sonarr radarr samba-smbd
  systemd.services.qbittorrent = externalwd;
  systemd.services.plex = externalwd;
  systemd.services.jellyfin = externalwd;
  systemd.services.photoprism = externalwd;
  systemd.services.sonarr = externalwd;
  systemd.services.radarr = externalwd;
  systemd.services.samba-smbd = externalwd;

  # Push the failed boot mount to ntfy (notify-failure@ is in modules/monitoring.nix).
  systemd.units."mnt-externalwd.mount" = {
    overrideStrategy = "asDropin";
    text = ''
      [Unit]
      OnFailure=notify-failure@%n.service
    '';
  };

  networking.hostName = "tewenixsrv";

  networking.networkmanager.enable = true;
  networking.defaultGateway = "192.168.50.1";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
