{
  pkgs,
  lib,
  ...
}: {
  # Enable the Hyprland Wayland compositor
  programs.hyprland.enable = true;

  # Enable a display manager
  services.xserver.displayManager.lightdm.enable = true;

  # We need XWayland for backwards compatibility with X11 apps
  services.xserver.enable = true;
  
  # Install essential packages for a complete Hyprland environment.
  environment.systemPackages = with pkgs; [
    waybar         # A status bar for Wayland compositors like Hyprland
    rofi-wayland   # A Rofi fork for Wayland
    mako           # A notification daemon for Wayland
    swaylock       # A screen locker for Wayland
    grim           # A screenshot tool for Wayland
    slurp          # A tool to select a region for screenshots
  ];

  # Basic fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
  ];
}
