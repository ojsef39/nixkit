{
    description = "My Nix function library";

    outputs = { self }: 
        let
            # Import all function modules at once
            # lib = import ./modules;
        in {

            nixosModules.default  = {
                imports = [ ./modules];
            };

            homeModules.default = {
                imports = [./home];
            };
        };
}
