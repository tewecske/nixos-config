#!/usr/bin/env bash
#
# rollback — undo a bad `hm switch` by going back to a previous home-manager
# generation.
#
#   ./rollback.sh        roll back one step (to the generation before current)
#   ./rollback.sh 7      activate a specific generation by id
#
# Deliberately does NOT touch the flake: rollback has to work even when the
# current config fails to build — that is the whole point. So it runs
# identically on WSL, Ubuntu, Fedora and NixOS (all use the same standalone
# home-manager, no HM_TARGET needed).
#
# List generation ids with: home-manager generations

set -euo pipefail

if ! command -v home-manager >/dev/null 2>&1; then
  echo "rollback: home-manager is not on PATH" >&2
  exit 1
fi

gen="${1:-}"

if [[ -z "$gen" ]]; then
  # One step back. `switch --rollback` flips the profile pointer with
  # `nix-env --rollback` and runs the previous generation's activate script.
  exec home-manager switch --rollback
fi

if [[ ! "$gen" =~ ^[0-9]+$ ]]; then
  echo "rollback: expected a generation id (a number), got '$gen'" >&2
  exit 1
fi

# A specific generation: run that generation's activate script directly.
# `home-manager generations` prints one line per generation, e.g.
#   "2026-08-18 16:50 : id 9 -> /nix/store/...-home-manager-generation (current)"
path="$(home-manager generations | sed -n "s#.*id ${gen} -> \(/nix/store/[^ ]*\).*#\1#p")"

if [[ -z "$path" ]]; then
  echo "rollback: no generation ${gen}" >&2
  echo "Available generations:" >&2
  home-manager generations >&2
  exit 1
fi

echo "Activating generation ${gen}: ${path}"
exec "$path/activate"
