{
setDefaultBrowser = browser:
  let
    isLinux = builtins.currentSystem == "x86_64-linux" || 
              builtins.currentSystem == "i686-linux" ||
              builtins.currentSystem == "aarch64-linux";
  in
    if isLinux then
      # Linux-specific method using xdg-settings
      builtins.trace "Setting default browser on Linux to ${browser}"
      (builtins.exec ["xdg-settings" "set" "default-web-browser" "${browser}.desktop"])
    else
      # Non-Linux systems use the original method
      builtins.trace "Setting default browser to ${browser}"
      (builtins.exec ["defaultbrowser" browser]);
}
