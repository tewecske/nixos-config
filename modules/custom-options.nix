{ lib, ... }:

{
  options.mySystem.profile = lib.mkOption {
    type = lib.types.str;
    default = "";
    description = ''
      The profile type for this system, used to determine which
      machine-specific configurations to apply.
      Examples: "desktop", "server", "laptop"
    '';
  };
}
