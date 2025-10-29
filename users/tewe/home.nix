{ config, pkgs, profile, ... }: # Add 'profile' to the function arguments

{
  # First, import the common configuration that applies to all hosts.
  imports = [ ./common.nix ]

  # Then, add machine-specific configurations based on the profile.
  ++ (if profile == "desktop" then
      # Import desktop-specific settings
      [ ./desktop.nix ]
    else if profile == "server" then
      # Import server-specific settings
      [ ./server.nix ]
    else
      # Default to an empty list if the profile doesn't match
      [ ]);
}
