{ config, lib, pkgs, ... }:

let
  cfg = config.services.hyperkey;

hyperkey = pkgs.stdenv.mkDerivation {
  pname = "hyperkey";
  version = "local";

  src = ./hyperkey;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/hyperkey
    chmod +x $out/bin/hyperkey
    runHook postInstall
  '';

  meta = with lib; {
    description = "Remaps Caps Lock to a Hyper key";
    license = licenses.mit;
    platforms = platforms.darwin;
  };

  __darwinAllowLocalNetworking = true;

  postInstall = ''
    echo "NOTE: HyperKey requires accessibility permissions."
    echo "      Please grant them in System Settings → Privacy & Security → Accessibility."
  '';
};

  launchAgentConfig = {
    ProgramArguments = [
      "${hyperkey}/bin/hyperkey"
    ]
    ++ (if !cfg.normalQuickPress then ["--no-quick-press"] else [])
    ++ (if cfg.includeShift then ["--include-shift"] else []);
    RunAtLoad = true;
    KeepAlive = true;
    EnvironmentVariables = {
        PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
    };
    SessionCreate = true;
  };
in {
  options.services.hyperkey = {
    enable = lib.mkEnableOption "HyperKey service that remaps Caps Lock to a Hyper key";

    normalQuickPress = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        If enabled, a quick press of the Caps Lock key will send an Escape key.
        If disabled, it will only act as the Hyper key.
      '';
    };

    includeShift = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If enabled, the Hyper key will include the Shift modifier (Cmd+Ctrl+Opt+Shift).
        If disabled, it will only include Cmd+Ctrl+Opt.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ hyperkey ];
    launchd.user.agents.hyperkey.serviceConfig = launchAgentConfig;
  };
}
