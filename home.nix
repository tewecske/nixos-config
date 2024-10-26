{ config, pkgs, ... }:

{
  home.username = "tewe";
  home.homeDirectory = "/home/tewe";
  home.packages = with pkgs; [
    neovim
    yazi

    zip
    xz
    unzip
    p7zip

    ripgrep
    jq
    fzf
    
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
  ];

  programs.git = {
    enable = true;
    userName = "tewe";
    userEmail = "leventewe@gmail.com";
  };

  programs.starship = {
    enable = true;
    settings = {
      gcloud.disabled = true;
    };
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    bashrcExtra = ''
      export PATH="$PATH:$HOME/bin:$HOME/.local/bin"
    '';
    shellAliases = {
      vimdiff = "nvim -d";
    };
  };

  home.stateVersion = "24.05";

  programs.home-manager.enable = true;
}
