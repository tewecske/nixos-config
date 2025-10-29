{ pkgs, ... }:

# terminals

let
  font = "JetBrainsMono Nerd Font";
in
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local config = wezterm.config_builder()

      config.color_scheme = 'Catppuccin Mocha'
      config.enable_tab_bar = true
      config.hide_tab_bar_if_only_one_tab = true
      config.font_size = 12.0
      config.font = wezterm.font_with_fallback {
          { family = 'MesloLGMDZ Nerd Font', weight = 'Bold' },
        'MesloLGMDZ Nerd Font',
        'JetBrainsMono Nerd Font'
      }
      config.window_background_opacity = 1.0
      config.window_decorations = "TITLE | RESIZE"
      config.window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
      }
      config.keys = {
        {
          key = 'f',
          mods = 'CTRL',
          action = wezterm.action.ToggleFullScreen,
        },
        {
          key = "'",
          mods = 'CTRL',
          action = wezterm.action.ClearScrollback 'ScrollbackAndViewport',
        },
      }
      config.mouse_bindings = {
        {
          event = { Up = { streak = 1, button = 'Left' } },
          mods = 'CTRL',
          action = wezterm.action.OpenLinkAtMouseCursor,
        },
      }

      return config
    '';
  };
}
