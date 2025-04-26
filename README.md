# A Collection of various nix utilities


## Installation


Add it to your `flake.nix` inputs:
```nix
nix-utils = {
    url = "github:frostplexx/nixkit";
    # or for local development:
    # url = "path:/Users/daniel/Developer/nix-utils";
};
```
Add the home manager module:
```nix
home-manager = {
    sharedModules = [
        inputs.nixkit.homeModules.default
    ];
};
```
Add the nix module:
```nix
modules = [
    inputs.nixkit.nixosModules.default
];
```


## Home Manager Modules

### Set Default Browser

To set the default browser on macOS and Linux use the following:
```nix
# Enable and configure the default browser
programs.default-browser = {
    enable = true;
    browser = "firefox"; # Or any other browser name
};
```


## System Modules

### Hyperkey

`hyperkey` is a simple serivce that maps caps-lock to cmd+opt+ctrl or optionally cmd+opt+ctrl+shift.
Simply enable it using the following snippet inside your `configuration.nix`:
```nix
services.hyperkey = {
    enable = true;
    normalQuickPress = true; # Quick press of Caps Lock to toggle it
    includeShift = false; # Hyper key will be Cmd+Ctrl+Opt (without Shift)
};
```
On first start it will ask for accessibility permission. Afterwards you may need to restart the service by running `killall hyperkey` for the permissions to
take effect.


### Declare Folders

SOON

### Auto Fetch Flake and Update

SOON
