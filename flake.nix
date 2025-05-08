{
    description = "Various modules and utilities for NixOS and nix-darwin";

    inputs = {

    };

    outputs = { ... }: {

        nixosModules.default  = {
            imports = [./modules/shared ./modules/nixos];
        };

        darwinModules.default  = {
            imports = [./modules/shared ./modules/darwin];
        };

        homeModules.default = {
            imports = [./home];
        };
    };
}
