# A Collection of various nix utilities


## Installation


Add it to your `flake.nix` inputs:
```nix
nix-utils = {
    url = "github:frostplexx/nix-utils";
    # or for local development:
    # url = "path:/Users/daniel/Developer/nix-utils";
};
```
Add the home manager module:
```nix
home-manager = {
    sharedModules = [
        inputs.nix-utils.homeModules.default
    ];
};
```
Add the nix module:
```nix
modules = [
    inputs.nix-utils.nixosModules.default
];
```


## Home Manager Functions

### Set Default Browser

To set the default browser on macOS and Linux use the following:
```nix
# Enable and configure the default browser
programs.default-browser = {
    enable = true;
    browser = "firefox"; # Or any other browser name
};
```
