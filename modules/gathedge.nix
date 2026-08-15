# GathEdge — ZIO HTTP backend + Scala.js/Laminar SPA.
#
# The app's own flake carries the NixOS module (services.gathedge); this file is the host's
# half of the contract. That module is deliberately additive — it contributes a database, a
# role and an nginx vhost, and asserts that the host turns Postgres and nginx on — so that a
# second app later merges in without conflict.
#
# Reached from outside through the Cloudflare tunnel in modules/cloudflared.nix: its ingress
# points a public hostname at http://localhost:80, where nginx serves the SPA and proxies /api
# to the backend on loopback. That ingress lives in the Cloudflare dashboard, not here — the
# tunnel is token-managed.
{ config, pkgs, inputs, ... }:
{
  imports = [ inputs.gathedge.nixosModules.default ];

  services.postgresql = {
    enable = true;
    # Pinned rather than left to the nixpkgs default: a major-version bump moves the data
    # directory format, and NixOS will not migrate it for you.
    package = pkgs.postgresql_16;
  };

  services.nginx.enable = true;

  # Same shape as the cloudflared token: a systemd EnvironmentFile, decrypted to
  # /run/secrets/gathedge/env, never in the (world-readable) Nix store.
  #
  # Read by two units — the backend, and the gathedge-db-password oneshot that ALTERs the
  # Postgres role to match DB_PASSWORD, since services.postgresql.ensureUsers cannot set one.
  sops.secrets."gathedge/env" = {
    mode = "0400";
    owner = "root";
    group = "root";
  };

  services.gathedge = {
    enable = true;

    # The public hostname routed here by the weecaldemo tunnel. Also the default vhost, so
    # reaching the server by bare IP on the LAN lands on the same site.
    hostName = "gathedge.200iq.link";
    publicBaseUrl = "https://gathedge.200iq.link";

    # Not the module's default of 8080: qbittorrent-nox's WebUI already has that
    # (modules/torrent.nix), and the backend would fail to bind. Loopback only either way —
    # nginx is the only thing that talks to it.
    port = 8081;

    # cloudflared sets X-Forwarded-For to the real client, then nginx appends its own peer
    # (127.0.0.1), giving [client, 127.0.0.1] — so the client sits 2 in from the right. A
    # request that arrives directly on the LAN carries a 1-entry header instead, the lookup
    # misses, and RouteSupport.clientAddress falls back to the socket peer, which is the
    # right answer there too.
    trustedProxyHops = 2;

    # Stays false until the bootstrap admin exists: AdminSeeder does not run in production,
    # and nothing else creates an administrator from nothing. Sign in, change the password,
    # then flip this to true — after which only the https origin can authenticate, because a
    # Secure cookie is never sent over plain HTTP.
    production = false;

    # A string, not a path literal: a path would be copied into the Nix store at evaluation,
    # which is exactly what the secret must not be. Equal to
    # config.sops.secrets."gathedge/env".path.
    environmentFile = "/run/secrets/gathedge/env";

    captcha.siteKey = "0x4AAAAAAERIYkM5j5Z4gTDh";
  };

  # The app module's openFirewall opens port 80, which is a no-op on this host —
  # modules/system.nix sets networking.firewall.enable = false.
}
