# Alerting for tewenixsrv, all pushed to the ntfy topic in secrets.yaml (ntfy_topic).
#
# - Netdata: disk space, sustained CPU, memory (stock alerts + one CPU override below).
#   Dashboard on loopback only: `ssh -L 19999:localhost:19999 tewenixsrv`.
# - notify-failure@: OnFailure hook that pushes the unit's last log lines.
# - security-update-check: weekly, compares the running nixpkgs against the release branch
#   and pushes when CVE fixes landed for packages in this system's closure.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  topicPath = config.sops.secrets.ntfy_topic.path;
  release = config.system.nixos.release; # "26.05"
  branch = "nixos-${release}";

  # .05 releases get fixes until the end of December, .11 releases until the end of June.
  eol =
    let
      parts = lib.splitString "." release;
      year = 2000 + lib.toInt (builtins.head parts);
    in
    if lib.last parts == "05" then "${toString year}-12-31" else "${toString (year + 1)}-06-30";

  # Units whose failure should page. Long-running services with Restart= only reach
  # "failed" once systemd gives up restarting them.
  watchedUnits = [
    "gathedge-backup"
    "gathedge-backend"
    "gathedge-db-password"
    "postgresql"
    "nginx"
    "security-update-check"
  ];
in
{
  # Netdata's alarm-notify.sh reads the topic directly, so the netdata group needs it.
  sops.secrets.ntfy_topic = {
    group = "netdata";
    mode = "0440";
  };

  ### Netdata ###

  services.netdata = {
    enable = true;
    config.web."bind to" = "127.0.0.1 ::1";
    configDir = {
      # Sourced as bash by alarm-notify.sh after the stock file; the topic stays out of the store.
      "health_alarm_notify.conf" = pkgs.writeText "health_alarm_notify.conf" ''
        SEND_NTFY="YES"
        DEFAULT_RECIPIENT_NTFY="https://ntfy.sh/$(cat ${topicPath})"
      '';
      # Stock alerts already cover disk (warn 80%, crit 90%), RAM (warn 80%, crit 90%) and
      # 10-minute CPU (warn 85%). This adds the "over 80% for a long time" case.
      "health.d/tewenixsrv.conf" = pkgs.writeText "tewenixsrv.conf" ''
        template: tewe_cpu_80_15min
              on: system.cpu
          lookup: average -15m unaligned of user,system,softirq,irq,guest
           units: %
           every: 1m
            warn: $this > 80
           delay: down 15m multiplier 1.5 max 1h
         summary: CPU above 80% for 15 minutes
            info: Average CPU utilization over the last 15 minutes
              to: sysadmin
      '';
    };
  };

  ### Unit failure -> ntfy ###

  systemd.services =
    lib.genAttrs watchedUnits (_: {
      onFailure = [ "notify-failure@%n.service" ];
    })
    // {
      "notify-failure@" = {
        description = "Push failure of %i to ntfy";
        path = with pkgs; [
          curl
          systemd
        ];
        serviceConfig = {
          Type = "oneshot";
          LoadCredential = "topic:${topicPath}";
        };
        scriptArgs = "%i";
        script = ''
          unit="$1"
          curl -fsS --retry 3 \
            -H "Title: tewenixsrv: $unit failed" -H "Priority: high" -H "Tags: rotating_light" \
            -d "$(journalctl -u "$unit" -n 15 --no-pager -o cat)" \
            "https://ntfy.sh/$(cat "$CREDENTIALS_DIRECTORY/topic")"
        '';
      };

      ### Weekly security update check ###

      security-update-check = {
        description = "Check ${branch} for security fixes newer than the running system";
        path = with pkgs; [
          curl
          jq
          nix
          gnugrep
          coreutils
        ];
        serviceConfig = {
          Type = "oneshot";
          LoadCredential = "topic:${topicPath}";
        };
        script = ''
          rev=${config.system.nixos.revision}
          built=$(echo ${config.system.nixos.version} | cut -d. -f3 | cut -c1-8)
          age=$(( ( $(date +%s) - $(date -d "$built" +%s) ) / 86400 ))

          # Commits on the branch since our rev (compare endpoint pages at 100).
          msgs=$(mktemp)
          ahead=0
          for page in $(seq 1 20); do
            json=$(curl -fsS --retry 3 \
              "https://api.github.com/repos/NixOS/nixpkgs/compare/$rev...${branch}?per_page=100&page=$page")
            ahead=$(jq .ahead_by <<<"$json")
            n=$(jq '.commits | length' <<<"$json")
            jq -r '.commits[].commit.message
              | select(test("CVE-[0-9]+-[0-9]+"; "i")) | split("\n")[0]' <<<"$json" >> "$msgs"
            [ "$n" -lt 100 ] && break
          done

          # Keep only fixes whose package ("foo: 1.0 -> 1.1", "a,b: ...") is in our closure.
          closure=$(nix-store -qR /run/current-system)
          relevant=""
          while IFS= read -r title; do
            for name in $(cut -d: -f1 <<<"$title" | tr ',' ' '); do
              base=''${name##*.}; base=''${base%%_[0-9]*}
              if grep -qE "^/nix/store/[a-z0-9]{32}-$base-[0-9]" <<<"$closure"; then
                relevant+="- $title"$'\n'
                break
              fi
            done
          done < <(sort -u "$msgs")
          others=$(( $(sort -u "$msgs" | wc -l) - $(printf '%s' "$relevant" | grep -c . || true) ))

          days_to_eol=$(( ( $(date -d ${eol} +%s) - $(date +%s) ) / 86400 ))

          body="" prio=default
          if [ -n "$relevant" ]; then
            prio=high
            body+="CVE fixes for installed packages:"$'\n'"$relevant"
          fi
          if [ -n "$relevant" ] || [ "$age" -gt 30 ]; then
            body+="Running nixpkgs is $age days / $ahead commits behind ${branch} ($others other CVE fixes)."$'\n'
            body+="Update: nix flake update nixpkgs && sudo nixos-rebuild switch --flake ~/nixos-config#tewenixsrv"$'\n'
          fi
          if [ "$days_to_eol" -lt 45 ]; then
            body+="NixOS ${release} stops getting fixes on ${eol} ($days_to_eol days). Move to the next release."$'\n'
          fi

          if [ -n "$body" ]; then
            curl -fsS --retry 3 \
              -H "Title: tewenixsrv updates" -H "Priority: $prio" -H "Tags: shield" \
              -d "$body" "https://ntfy.sh/$(cat "$CREDENTIALS_DIRECTORY/topic")"
          else
            echo "Nothing to report: $age days / $ahead commits behind, $others irrelevant CVE fixes."
          fi
        '';
      };
    };

  systemd.timers.security-update-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sat 10:00";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
  };
}
