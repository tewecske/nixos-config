{ pkgs, inputs, ... }: {

  imports = [
    ../../home/core.nix
    ../../home/programs
    ../../home/shell
  ];

  home.file = {
    ".bashrc" = {
      source = inputs.tewenixhome + "/.bashrc";
    };
    ".gitconfig" = {
      source = inputs.tewenixhome + "/.gitconfig";
    };
    # Place the reset config in the .config/tmux/ directory
    ".config/tmux/tmux.reset.conf" = {
      source = inputs.tewenixhome + "/tmux/tmux.reset.conf";
    };
  };

  # Enable and configure tmux.
  programs.tmux = {
    enable = true;
    # Tell home-manager to use your tmux.conf from the repo.
    # This will place it at ~/.config/tmux/tmux.conf by default.
    configFile.source = inputs.tewenixhome + "/tmux/tmux.conf";

    plugins = with pkgs.tmuxPlugins; [
      tmux-resurrect
      tmux-continuum
      tmux-thumbs
      tmux-fzf
      catppuccin
    ];
  };
}
