{
  pkgs,
  lib,
  ...
}: {

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the i3 window manager.
  # We use i3-gaps for more features like gaps between windows.
  services.xserver.windowManager.i3.enable = true;
  services.xserver.windowManager.i3.package = pkgs.i3-gaps;

  # Enable LightDM, a lightweight display manager.
  services.xserver.displayManager.lightdm.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Install essential packages for a complete i3 environment.
  environment.systemPackages = with pkgs; [
    i3status  # Status bar for i3
    i3lock    # Screen locker
    rofi      # A powerful application launcher
  ];

}