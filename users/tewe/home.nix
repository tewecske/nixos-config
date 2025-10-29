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
      source = inputs.tewenixhome + "/.config/tmux/tmux.reset.conf";
    };
    # Place the main tmux config in the correct directory
    ".config/tmux/tmux.conf" = {
      source = inputs.tewenixhome + "/.config/tmux/tmux.conf";
    };
  };

  # Enable and configure tmux.
  programs.tmux = {
    enable = true;

    # The tmux module will automatically use the config file we placed
    # with home.file at ~/.config/tmux/tmux.conf

    plugins = with pkgs.tmuxPlugins; [
      tmux-resurrect
      tmux-continuum
      tmux-thumbs
      tmux-fzf
      catppuccin
    ];
  };
}
