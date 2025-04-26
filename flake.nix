{
    description = "Various modules and utilities for NixOS and nix-darwin";

    inputs = {

    };

    outputs = { ... }: {

        nixosModules.default  = {
            imports = [./modules];
        };

        homeModules.default = {
            imports = [./home];
        };
    };
}
