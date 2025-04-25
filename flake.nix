{
    description = "My Nix function library";

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
