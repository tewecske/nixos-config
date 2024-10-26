{
  lib,
  pkgs,
  catppuccin-bat,
  ...
}: {
  home.packages = with pkgs; [
    neovim
    yazi

    # archives
    zip
    unzip
    p7zip

    # utils
    ripgrep
    jq
    fzf
    #yq-go # https://github.com/mikefarah/yq

    dnsutils #dig nslookup
    nmap

    file
    which
    tree
    gnused
    gnutar
    gawk
    zstd
    gnupg

    nix-output-monitor

    htop
    btop
    iotop
    iftop

    strace
    ltrace
    lsof

    sysstat
    lm_sensors #sensors
    ethtool
    pciutils #lspci
    usbutils #lsusb

    # misc
    # libnotify
    # wineWowPackages.wayland
    # xdg-utils
    # graphviz

    # cloud native
    # docker-compose
    # kubectl

    # nodejs
    # nodePackages.npm
    # nodePackages.pnpm
    # yarn

    # db related
    # dbeaver-bin
    # mycli
    # pgcli
  ];

  programs = {
    tmux = {
      enable = true;
      clock24 = true;
      keyMode = "vi";
      extraConfig = "mouse on";
    };

    starship = {
      enable = true;
      settings = {
        gcloud.disabled = true;
      };
    };

    bash = {
      enable = true;
      enableCompletion = true;
      bashrcExtra = ''
        export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
      '';
      shellAliases = {
        vimdiff = "nvim -d";
      };
      shellInit = ''
        bind '"\e[A":history-search-backward'
        bind '"\e[B":history-search-forward'
      '';
    };

    bat = {
      enable = true;
      config = {
        pager = "less -FR";
        theme = "catppuccin-mocha";
      };
      themes = {
        # https://raw.githubusercontent.com/catppuccin/bat/main/Catppuccin-mocha.tmTheme
        catppuccin-mocha = {
          src = catppuccin-bat;
          file = "Catppuccin-mocha.tmTheme";
        };
      };
    };

    btop.enable = true; # replacement of htop/nmon
    # eza.enable = true; # A modern replacement for ‘ls’
    jq.enable = true; # A lightweight and flexible command-line JSON processor
    ssh.enable = true;
    # aria2.enable = true; # lightweight download utility

    # ? fuzzy finder ?
    # skim = {
    #   enable = true;
    #   enableZshIntegration = true;
    #   defaultCommand = "rg --files --hidden";
    #   changeDirWidgetOptions = [
    #     "--preview 'exa --icons --git --color always -T -L 3 {} | head -200'"
    #     "--exact"
    #   ];
    # };
  };

  services = {
    # decentralized file sync service
    # syncthing.enable = true;

    # auto mount usb drives
    udiskie.enable = true;
  };
}
