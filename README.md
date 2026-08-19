# nixos-config

A single flake covering both halves:

- **NixOS system** for the server (`tewenixsrv`) — `nixosConfigurations`, with
  the host config under `hosts/`, shared modules under `modules/`, and secrets
  via `sops`.
- **Home environment** for every machine (WSL, Ubuntu, Fedora, NixOS) —
  standalone [home-manager](https://github.com/nix-community/home-manager),
  one `homeConfigurations` entry per machine.

Nix provides **all** the tooling. `sdkman`, `cs setup`, `fnm` and `go install`
are no longer used — see [What replaced what](#what-replaced-what).

```
flake.nix              # inputs + nixosConfigurations.tewenixsrv + homeConfigurations.*
hosts/tewenixsrv/      # server NixOS config + hardware-configuration.nix
modules/               # NixOS system modules (system, cloudflared, gathedge, ...)
users/tewe/nixos.nix   # tewe user SSH authorizedKeys (system level)
secrets.yaml .sops.yaml
home/common.nix        # packages + dotfile symlinks (shared by all machines)
home/{wsl,ubuntu,fedora,nixos}.nix
home/programs/         # bash, git, tmux, fzf, starship, zoxide, dircolors, home-manager
bash/                  # .bashrc .profile .bash_aliases   -> symlinked to ~
scripts/               #                                  -> symlinked to ~/bin/scripts
examples/devenv.nix    # optional per-project toolchains
linstalls.log          # historical record of the old manual install
```

> The repo must live at `~/nixos-config` — `home/common.nix` symlinks dotfiles
> out of it, and the `hm` wrapper hardcodes that path.

---

## Server (tewenixsrv)

### Migrate / bootstrap

1. Nix is already there. On a *fresh* NixOS install you first need flakes
   enabled — until the config itself sets them (`modules/system.nix` does):

   ```nix
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   ```

2. Clone and apply the **system** config (also sets `nix-ld`, openssh, and the
   server modules):

   ```sh
   git clone git@github.com:tewecske/nixos-config.git ~/nixos-config
   sudo nixos-rebuild switch --flake ~/nixos-config#tewenixsrv
   ```

3. The **sops age key** must be in place before step 2 (it decrypts
   `secrets.yaml` → `rclone.conf`, so the rebuild fails without it):

   ```sh
   install -Dm600 <age-keys.txt> ~/.config/sops/age/keys.txt
   ```

4. Apply the **user** environment (same standalone home-manager config as every
   other machine, target `tewe@nixos`):

   ```sh
   hm switch
   ```

Server-only admin tooling (nmap, rclone, btop, …), `nix-ld`, and the rclone
sops secret live at the system level in `modules/system.nix`.

### Rollback

- One generation back (system):

  ```sh
  sudo nixos-rebuild switch --rollback
  ```

- List system generations:

  ```sh
  nixos-rebuild list-generations
  ```

- Boot-time fallback: `systemd-boot` keeps 10 generations
  (`boot.loader.systemd-boot.configurationLimit` in `hosts/tewenixsrv/default.nix`)
  — pick an older entry from the boot menu.
- Home-manager on the server: same `./rollback.sh` as everywhere else.

---

## Bootstrap a machine

### 1. Install nix — *this is the manual step*

Skip on **NixOS** (nix is already there; go to step 2).

Recommended, on WSL / Ubuntu / Fedora — the Determinate Systems installer, which
turns flakes on by default and handles SELinux (Fedora) and WSL correctly:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

<details>
<summary>Upstream installer instead</summary>

```sh
sh <(curl -L https://nixos.org/nix/install) --daemon
mkdir -p ~/.config/nix
echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```
</details>

Then **open a new shell** so `/nix` lands on `PATH`, and check:

```sh
nix --version
```

> WSL only: the multi-user install needs systemd. This machine already has
> `systemd=true` in `/etc/wsl.conf`. On a fresh WSL instance, add it, then
> `wsl --shutdown` from Windows first.

### 2. Clone this repo

```sh
git clone git@github.com:tewecske/nixos-config.git ~/nixos-config
```

The path must be `~/nixos-config` — `home/common.nix` symlinks dotfiles out of it.

### 3. Apply home-manager

home-manager needs **no separate install**; `nix run` fetches it:

```sh
cd ~/nixos-config
nix run home-manager/master -- switch -b backup --flake .#tewe@wsl
```

Swap the last argument per machine: `.#tewe@ubuntu`, `.#tewe@fedora`, `.#tewe@nixos`.

`-b backup` is required on the **first** run: `~/.bashrc`, `~/.profile` and
`~/.gitconfig` already exist, and home-manager refuses to clobber unmanaged files.
It renames them to `*.backup`. Later runs don't need the flag.

After the first switch, `home-manager` is on `PATH`:

```sh
home-manager switch --flake ~/nixos-config#tewe@wsl
```

### 4. Neovim config

Already included in this repo under `nvim/`. Step 3 symlinks it to
`~/.config/nvim` (out-of-store, so edits are live), so there is nothing to clone —
just run `nvim`. Plugins install on first launch via `:h vim.pack`.

### 5. tmux plugins

tmux config lives entirely in `home/programs/tmux.nix`. Plugins are managed
natively by home-manager from nixpkgs `tmuxPlugins` — no tpm, no `prefix + I`.
Add/remove a plugin by editing the `plugins` list, then `hm switch`.

### 6. NixOS only — nix-ld

Prebuilt dynamically linked binaries expect `/lib64/ld-linux-x86-64.so.2`, which
NixOS does not have, so they fail to exec without nix-ld.

For `tewenixsrv` this is already set in `modules/system.nix`. For any *other*
NixOS host using `tewe@nixos`, add to its system config:

```nix
programs.nix-ld.enable = true;
programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc.lib zlib openssl ];
```

then `sudo nixos-rebuild switch`. Unnecessary on WSL/Ubuntu/Fedora.

---

## Daily use

The config is a flake, so it is **not** at home-manager's default
`~/.config/home-manager/home.nix`. Bare `home-manager news` therefore fails with
"No configuration file found" — every subcommand needs `--flake`. The `hm`
wrapper in `bash/.bash_aliases` supplies it, using `HM_TARGET` (set per machine
in `home/<host>.nix`).

| | |
|---|---|
| apply changes | `hm switch` |
| what changed upstream | `hm news` |
| build without activating | `hm build` |
| add a package | edit `home/common.nix`, then `hm switch` |
| update everything | `nix flake update` in `~/nixos-config`, then `hm switch` |
| roll back | `./rollback.sh` (one step) or `./rollback.sh N` (specific generation) |
| find a package name | `nix search nixpkgs ripgrep` |
| format the nix files | `nix fmt` |

### Rolling back

`hm switch` keeps every previous generation around (see
`home-manager generations`), so a bad switch is always reversible. `rollback.sh`
at the repo root does the undo — it works unchanged on WSL, Ubuntu, Fedora and
NixOS because it does **not** touch the flake. Rollback has to work even when
the current config fails to build, so it needs neither `HM_TARGET` nor a valid
flake:

```sh
./rollback.sh      # one step back, to the generation before the current one
./rollback.sh 7    # activate a specific generation (list ids with `home-manager generations`)
```

By hand, without the script:

```sh
home-manager switch --rollback                      # one step back
home-manager generations                            # note the id / store path
/nix/store/...-home-manager-generation/activate     # activate a specific one
```

### PATH ordering — read before editing bash/

Login shell order is: `.profile` sources `.bashrc` **first**, then prepends its
own dirs. So anything that prepends to `PATH` *after* the nix block shadows the
nix profile.

The nix block is therefore the **last** thing in `.bashrc`, and these are
commented out because each one prepends a competing toolchain:

| block | file | shadows |
|---|---|---|
| `/usr/local/go/bin` | `.profile` | `go` |
| sdkman init | `.bashrc` | `java` |
| fnm init | `.bashrc` | `node`, `npm` |

Re-enable any of them and that tool stops coming from nix. Verify with:

```sh
env -i HOME="$HOME" TERM=xterm PATH=/usr/bin:/bin bash -lic 'command -v go java node'
```

`flake.lock` pins every input — commit it. Two machines on the same lock get
byte-identical tooling.

### Editing dotfiles

`bash/` and `scripts/` are linked with `mkOutOfStoreSymlink`, so they point at
`~/nixos-config/...` rather than into the nix store. Edit them and the change is
live — **no switch needed**. Only adding or removing a *file* needs a switch.
(tmux is different: it's generated by `programs.tmux`, so edits go in
`home/programs/tmux.nix` and need a switch.)

### Monitor hotplug — Fedora/i3 only

X does not disable an output when you pull the cable: the CRTC stays mapped, so
i3 keeps a workspace on a screen that no longer exists and its windows become
unreachable. `scripts/display-hotplug` fixes that, and the reverse case.

`home/fedora.nix` runs it as a **systemd user unit** (`display-hotplug`) that
watches `udevadm monitor --udev --subsystem-match=drm`. Nothing needs root:
udev's userspace events are readable unprivileged, and lightdm already exports
`DISPLAY`/`XAUTHORITY` into the `systemctl --user` environment.

On each event it:

- lays the internal panel out at `0x0` as primary, every external `--right-of`
  the previous one;
- `--off`s any output that is enabled with nothing plugged into it, which is
  what makes i3 pull the stranded workspaces back;
- switches the audio card profile between `output:hdmi-stereo+input:analog-stereo`
  and `output:analog-stereo+input:analog-stereo`, sets the default sink and
  moves playing streams over — i.e. the pavucontrol step, automated.

This laptop's monitor reports no ELD, so pipewire marks the HDMI profiles
`available: no` even while sound works. The script therefore sets the profile
and checks whether it stuck, rather than trusting availability.

Workspace 2 is pinned to the external screen by one line in
`~/.config/i3/config` (not managed by this repo):

```
workspace $ws2 output HDMI-1 DP-1 DP-2 primary
```

| | |
|---|---|
| repair the layout by hand | `display-hotplug` (it is on `PATH` via `~/bin/scripts`) |
| watch what it does | `journalctl --user -u display-hotplug -f` |
| after editing the script | `systemctl --user restart display-hotplug` |
| different workspace on the external | `EXTERNAL_WS=3 display-hotplug`, and edit the i3 line |

---

## What replaced what

| was | now |
|---|---|
| `sdkman` → jdk | `jdk21` |
| `cs setup`, `cs install mill` | `scala_3` `sbt` `mill` `metals` |
| `fnm use --install-if-missing 20` | `nodejs_22`, `pnpm` |
| `go install .../air`, `.../templ` + manual `~/bin` symlinks | `air`, `templ` |
| `apt install ripgrep jq fzf` etc. | one `home.packages` list |
| `curl … starship.rs/install.sh` | `starship` |
| `rustup` | `rustc` `cargo` `rust-analyzer` |

`coursier` is still installed: `nvim-metals` shells out to `cs` for
`:MetalsInstall`. It is a tool now, not an environment manager — no `cs setup`.

Dropped, per your call: `pdftotext` (poppler-utils), `7zip`, `zoxide`, `fd-find`.
Commented out in `home/common.nix`: `sqlite`, `tailwindcss`.

---

## Optional: per-project toolchains with devenv

home-manager gives every machine the same base environment. **devenv** is a
different axis — per-*directory* toolchains that activate on `cd`, for when a
project needs a JDK or Node version that differs from the base.

You don't need it to get started; it layers on later with no rework.

```sh
nix profile install nixpkgs#devenv nixpkgs#direnv
cd ~/projects/some-repo
cp ~/nixos-config/examples/devenv.nix .
echo 'use devenv' > .envrc && direnv allow
```

See `examples/devenv.nix`. Files: `devenv.nix` (config), `devenv.yaml`
(inputs), `devenv.lock` (pins). Docs: <https://devenv.sh>.

---

## Not covered here

- SSH keys — copy them in before cloning (`linstalls.log` lines 4-6).
- Windows-side WSL setup — see `windows_setup.txt`.
- `sops`/`age` key material — see `nix_stuff.txt`.
