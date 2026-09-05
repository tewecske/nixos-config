{
  pkgs,
  nixGL,
  system,
  ...
}:
let
  # wezterm's GUI front end needs EGL/GLX; nix's loader doesn't search
  # /usr/lib/x86_64-linux-gnu on foreign (non-NixOS) distros, so it fails
  # with "libEGL.so: cannot open shared object file". Wrap it with nixGL's
  # mesa, same trick used for nixGLIntel elsewhere in home/common.nix.
  wezterm-nixgl = pkgs.symlinkJoin {
    name = "wezterm-nixgl";
    paths = [ pkgs.wezterm ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      mv $out/bin/wezterm $out/bin/.wezterm-unwrapped
      makeWrapper ${nixGL.packages.${system}.nixGLIntel}/bin/nixGLIntel $out/bin/wezterm \
        --add-flags "$out/bin/.wezterm-unwrapped"
    '';
  };
in
{
  programs.wezterm = {
    enable = true;
    package = wezterm-nixgl;
    settings = {
      color_scheme = "Catppuccin Latte";

      # X11/i3 respects terminal cell increments when resizing.
      use_resize_increments = true;
      window_padding = {
        left = 0;
        right = 0;
        top = 0;
        bottom = 0;
      };

      ssh_domains = [
        {
          name = "teweora";
          remote_address = "138.2.190.84";
          username = "tewe";
          multiplexing = "WezTerm";
        }
      ];
    };

    extraConfig = ''
      local catppuccin_flavors = {
        "Catppuccin Latte",
        "Catppuccin Frappe",
        "Catppuccin Macchiato",
        "Catppuccin Mocha",
      }

      wezterm.on("cycle-catppuccin-flavor", function(window, pane)
        local overrides = window:get_config_overrides() or {}
        local current = overrides.color_scheme or window:effective_config().color_scheme
        local idx = 1
        for i, name in ipairs(catppuccin_flavors) do
          if name == current then
            idx = i
            break
          end
        end
        overrides.color_scheme = catppuccin_flavors[(idx % #catppuccin_flavors) + 1]
        window:set_config_overrides(overrides)
      end)

      return {
        keys = {
          { key = "]", mods = "CTRL|SHIFT", action = wezterm.action.EmitEvent("cycle-catppuccin-flavor") },
        },
      }
    '';
  };
}
