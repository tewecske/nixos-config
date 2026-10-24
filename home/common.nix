{
  pkgs,
  lib,
  config,
  system,
  nixGL,
  llm-agents,
  repoName,
  ...
}:

let
  # Absolute path to this repo as checked out on the machine.
  # Dotfiles are symlinked *out of* the nix store so you can edit them
  # in place and see the change immediately, with no `home-manager switch`.
  repo = "${config.home.homeDirectory}/${repoName}";
  link = path: config.lib.file.mkOutOfStoreSymlink "${repo}/${path}";

  # eMudhra CA compromise (Oct 2026): distrust the 8 compromised intermediates
  # by appending their SHA-256 fingerprints to the JDK's blocked.certs
  # (https://www.scala-lang.org/blog/jdk-certificate-vulnerability.html), and
  # drop the two roots they chain to, which Oracle says to do even on the fixed
  # releases (21.0.13 / 25.0.5). The store is read-only and rebuilding the JDK
  # from source is slow, so copy it and patch the copy; java.home resolves to
  # the copy.
  blockEmudhra =
    jdk:
    let
      self =
        pkgs.runCommand "${jdk.name}-emudhra-blocked"
          {
            inherit (jdk) meta;
            passthru = {
              inherit (jdk) version;
              home = "${self}/lib/openjdk";
            };
          }
          ''
            cp -a ${jdk} $out
            chmod -R u+w $out
            sec=$out/lib/openjdk/lib/security
            cat ${./emudhra-blocked.certs} >> $sec/blocked.certs
            for alias in "emsigneccrootcag3 [jdk]" "comodoaaaca [jdk]"; do
              $out/bin/keytool -delete -keystore $sec/cacerts -storepass changeit -alias "$alias"
            done
          '';
    in
    self;
  jdk25 = blockEmudhra pkgs.jdk25;
  # The scala tools default to nixpkgs' `jre` (jdk21); run them on jdk25 too.
  withJre = pkg: pkg.override { jre = jdk25; };
in
{
  imports = [
    ./programs/home-manager.nix
    ./programs/bash.nix
    ./programs/git.nix
    ./programs/tmux.nix
    ./programs/fzf.nix
    ./programs/starship.nix
    ./programs/dircolors.nix
    ./programs/zoxide.nix
    ./programs/direnv.nix
    ./programs/wezterm.nix
    ./programs/lazyenv.nix
  ];

  home.username = "tewe";
  home.homeDirectory = lib.mkDefault "/home/tewe";

  # Do not bump casually: it pins state-migration behaviour, not package versions.
  home.stateVersion = "25.05";

  #############################################################################
  # Packages
  #############################################################################
  home.packages = with pkgs; [
    # --- basic dev ------------------------------------------------------------
    # git and tmux come from programs.git / programs.tmux (home/programs/)
    curl
    wget
    unzip
    zip
    gnumake
    gcc
    python3 # treesitter parser build dep
    ffmpeg
    nerd-fonts.meslo-lg
    cascadia-code

    # --- cli ------------------------------------------------------------------
    bat
    ripgrep
    jq
    neovim
    gh
    lazygit
    just

    # --- jvm / scala  (replaces sdkman + `cs setup`) ---------------------------
    jdk25
    (withJre scala_3)
    (withJre scala-cli)
    (withJre sbt)
    (withJre mill)
    (withJre metals)
    (withJre coursier) # kept: nvim-metals shells out to `cs` for :MetalsInstall
    nixGL.packages.${system}.nixGLIntel

    # --- opengl on foreign distros --------------------------------------------
    # nix's loader doesn't search /usr/lib/x86_64-linux-gnu, so GL apps
    # (libGDX/LWJGL) can't find libGL. nixGLIntel wraps any command with nix's
    # own mesa (software GL): `nixGLIntel sbt run`. Aliased to `sbt` in
    # bash/.bash_aliases.

    # --- go  (replaces `go install ...` + hand-rolled ~/bin symlinks) ----------
    go_1_27
    gopls
    air
    templ
    delve # go debugger, driven by nvim-dap-go
    gocyclo
    ineffassign

    # --- node  (replaces fnm) -------------------------------------------------
    nodejs_26
    pnpm

    # --- rust  (was rustup in notes/linstalls.log) ----------------------------
    rustc
    cargo
    rust-analyzer

    # --- nix itself -----------------------------------------------------------
    nil # nix LSP
    nixfmt
    sops # `sops secrets.yaml` to edit; key at ~/.config/sops/age/keys.txt
    age

    # --- editor tooling (replaces mason.nvim) ---------------------------------
    # Language servers for languages that have no toolchain section above, plus
    # the formatters nvim shells out to. gopls / metals / rust-analyzer / nil
    # live with their toolchains.
    lua-language-server
    vscode-langservers-extracted # html, css, json, eslint servers
    tailwindcss-language-server
    emmet-language-server
    htmx-lsp
    stylua # lua formatter; lua_ls does not format
    tree-sitter # nvim-treesitter's `main` branch shells out to it to build parsers

    # --- ai --------------------------------------------------------------------
    # From numtide/llm-agents.nix (see flake.nix), prebuilt via cache.numtide.com.
    llm-agents.packages.${system}.claude-code
    llm-agents.packages.${system}.opencode2
    llm-agents.packages.${system}.amp
  ];

  #############################################################################
  # Dotfiles -> out-of-store symlinks into ~/nixos-config
  #############################################################################
  home.file = {
    ".bash_aliases".source = link "bash/.bash_aliases";
    "bin/scripts".source = link "scripts";
    ".config/nvim".source = link "nvim";
  };

  # ~/.config/nvim lives in this repo (nvim/), symlinked out-of-store like the
  # dotfiles above. nvim's built-in plugin manager (`:h vim.pack`) writes
  # nvim-pack-lock.json straight into nvim/ — commit it after updating.
  #
  # Language servers are NOT installed by nvim — Mason was removed. Every server
  # nvim enables must be on PATH from the list above.

  #############################################################################
  # Session
  #############################################################################
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "wezterm";
  };
}
