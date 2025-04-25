{ config, lib, pkgs, inputs, ... }:

with lib;

let
  cfg = config.services.hyperkey;


  # Define the HyperKey executable using swift-builders
  hyperkey = mkDynamicLibrary pkgs {
    pname   = "hyperkey";
    version = "0.1.0";
    src     = ./.;  # Directory containing your Swift source files
    target  = "hyperkey";

    # Pass SDK path and link required Apple frameworks
    extraCompilerFlags = [
      # Point swiftc at the macOS SDK in the Nix store
      "-sdk${pkgs.darwin.apple_sdk}/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
      # Ensure linking of system frameworks
      "-Xlinker" "-framework" "Carbon"
      "-Xlinker" "-framework" "Cocoa"
      "-Xlinker" "-framework" "Foundation"
      "-Xlinker" "-framework" "ApplicationServices"
    ];
  };

  launchAgentConfig = {
    ProgramArguments = [
      "${hyperkey}/bin/hyperkey"
    ]
    ++ (if !cfg.normalQuickPress then ["--no-quick-press"] else [])
    ++ (if cfg.includeShift then ["--include-shift"] else []);
    RunAtLoad = true;
    KeepAlive = true;
  };
in
{
    imports = [
        ../../lib/swift-builders.nix
    ];
  options.services.hyperkey = {
    enable = mkEnableOption "HyperKey service that remaps Caps Lock to Hyper key";

    normalQuickPress = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If enabled, a quick press of the Caps Lock key will send an Escape key.
        If disabled, it will only act as the Hyper key.
      '';
    };

    includeShift = mkOption {
      type = types.bool;
      default = false;
      description = ''
        If enabled, the Hyper key will include the Shift modifier (Cmd+Ctrl+Opt+Shift).
        If disabled, it will only include Cmd+Ctrl+Opt.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ hyperkey ];
    launchd.user.agents.hyperkey.serviceConfig = launchAgentConfig;

    system.activationScripts.postActivation.text = ''
      echo "NOTE: HyperKey requires accessibility permissions."
      echo "      Please grant them in System Settings → Privacy & Security → Accessibility."
    '';
  };
}
