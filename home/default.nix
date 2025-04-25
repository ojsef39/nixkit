let
  # Get all .nix files in the current directory except default.nix
  files = builtins.attrNames (builtins.readDir ./.);
  modules = builtins.filter 
    (name: name != "default.nix" && builtins.match ".*\\.nix" name != null) 
    files;
    
  # Import each module file
  importedModules = map 
    (name: import (./. + "/${name}")) 
    modules;
    
  # Merge all modules into a single attribute set
  merged = builtins.foldl' (acc: module: acc // module) {} importedModules;
in
  merged
