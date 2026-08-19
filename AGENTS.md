# AGENTS.md

Guidance for coding agents working in this repo.

## What this is

`~/nixos-config` is a single flake with two halves:

- **NixOS system** for the server (`nixosConfigurations.tewenixsrv`) — host
  config under `hosts/`, shared modules under `modules/`, secrets via `sops`.
- **Home environment** — standalone (flake-based) home-manager config that
  provisions the `tewe` dev environment identically on WSL2, Ubuntu, Fedora,
  and NixOS. The server applies this same config standalone (`tewe@nixos`).

Nix is the single source of tooling — sdkman, `cs setup`, fnm, and `go install`
are all superseded (see `README.md` "What replaced what").

## Secrets (sops-nix)

- Secrets live encrypted in `secrets.yaml` (`config.sops.defaultSopsFile` in
  `flake.nix` `commonModules`); wire new ones with `sops.secrets."name"` and read
  them via `config.sops.secrets."name"`.
- Age key is at `/home/tewe/.config/sops/age/keys.txt` (has a `TODO: fix this` in
  `flake.nix`). It must be in place **before** a server rebuild, or decrypting
  `secrets.yaml` fails.
- The rclone sops secret (`sops.secrets.rclone_config`) is decrypted into
  `~/.config/rclone/rclone.conf` by `modules/system.nix`.

## Layout

- `flake.nix` — inputs (nixpkgs stable + unstable, home-manager, opencode, nixGL,
  sops-nix, gathedge) + one `nixosConfigurations.tewenixsrv` + one
  `homeConfigurations` entry per host.
- `hosts/tewenixsrv/` — server NixOS config + hardware-configuration.nix.
- `modules/` — server NixOS modules (`system.nix`, `cloudflared.nix`,
  `gathedge.nix`, `plex.nix`, `jellyfin.nix`, `torrent.nix`, `photoprism.nix`,
  `samba.nix`). `system.nix` also carries the server-admin tools + rclone sops
  secret (moved out of home-manager).
- `users/tewe/nixos.nix` — tewe user SSH authorizedKeys (system level).
- `home/common.nix` — shared packages + dotfile symlinks; imports `home/programs/*.nix`.
- `home/{wsl,ubuntu,fedora,nixos}.nix` — per-host overrides; each sets `HM_TARGET`.
- `home/programs/*.nix` — one module per program (bash, git, tmux, fzf, starship, zoxide, dircolors, home-manager).
- `bash/`, `scripts/` — dotfiles symlinked out-of-store to `~/`.
- `nvim/` — Neovim config, symlinked out-of-store to `~/.config/nvim`.
- `home/programs/tmux.nix` — all tmux config (options, plugins, bindings); no `tmux/` dir.
- `examples/devenv.nix` — optional per-project toolchain.
- `linstalls.log`, `nix_stuff.txt`, `windows_setup.txt` — historical notes, not config.

## Conventions

- Server NixOS config builds against stable (`nixpkgs` = nixos-26.05); home-manager
  builds against `nixpkgs-unstable`. `cloudflared.nix` uses the unstable pin via
  `pkgs-unstable`.
- Dotfiles under `bash/`, `scripts/`, `nvim/` use `mkOutOfStoreSymlink` to point
  at `~/nixos-config/...` instead of the nix store. Editing them is live — no switch
  needed. Only adding/removing a *file* requires a switch.
- tmux is configured natively via `programs.tmux` (options + `plugins` from
  `pkgs.tmuxPlugins` + `extraConfig`). No tpm, no hand-written `tmux.conf`.
- nvim lives in this repo (`nvim/`), symlinked to `~/.config/nvim`. Its built-in
  plugin manager (`:h vim.pack`) writes `nvim-pack-lock.json` straight into
  `nvim/` — commit it after updating. Language servers come from nix (Mason removed).
- Formatter: `nixfmt-rfc-style` (run `nix fmt`). 2-space indent; section banners
  use `### ... ###` comment blocks.
- `home.stateVersion = "25.05"` — pinning migration behavior, do not bump casually.
- `flake.lock` is committed; two machines share byte-identical tooling.
- Server system config enables flakes + nix-command, weekly GC (`--delete-older-than 7d`),
  and `allowUnfree` (see `modules/system.nix`).

## Common tasks

| task | command |
|---|---|
| apply changes | `hm switch` |
| build without activating | `hm build` |
| upstream changes | `hm news` |
| add a package | edit `home/common.nix`, then `hm switch` |
| update everything | `nix flake update` then `hm switch` |
| rebuild the server | `sudo nixos-rebuild switch --flake ~/nixos-config#tewenixsrv` |
| test the server build | `sudo nixos-rebuild build --flake ~/nixos-config#tewenixsrv` |
| check the flake | `nix flake check` |
| format | `nix fmt` |
| find a package | `nix search nixpkgs <name>` |
| first run (existing dotfiles) | `home-manager switch -b backup --flake ~/nixos-config#tewe@<host>` |

`hm` is a wrapper in `bash/.bash_aliases` that supplies `--flake`; it reads
`HM_TARGET` (set per host). Everything needs `--flake` because the config is not
at the default `~/.config/home-manager/home.nix`.

## Gotchas

- PATH ordering in `bash/.bashrc`: the nix block is deliberately LAST. Any block
  that prepends to PATH after it (e.g. re-enabled fnm/sdkman/go) shadows nix.
- NixOS host needs `programs.nix-ld.enable = true` — already set for `tewenixsrv`
  in `modules/system.nix`; add manually on any other NixOS host.
- Fedora host runs `scripts/display-hotplug` as a systemd user unit (`display-hotplug`);
  restart with `systemctl --user restart display-hotplug` after editing.
- OpenGL on non-NixOS hosts (WSL/Ubuntu): nix's loader can't see the host's
  `/usr/lib/x86_64-linux-gnu`, so GL apps fail with `GLX: Failed to load GLX`.
  Run them through `nixGLIntel <cmd>` (aliased to `sbt` in `bash/.bash_aliases`).

## Author

tewe <leventewe@gmail.com> (GitHub: tewecske)
