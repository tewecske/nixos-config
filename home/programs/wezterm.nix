{ ... }:
{
  programs.wezterm = {
    enable = true;
    settings = {
      color_scheme = "Catppuccin Latte";
      ssh_domains = [
        {
          name = "teweora";
          remote_address = "138.2.190.84";
          username = "tewe";
          multiplexing = "WezTerm";
        }
      ];
    };
  };
}
