# Source: https://github.com/dduan/swift-builders/blob/main/lib.nix
let
  flattenBuildInputs = inputs:
    let
      iter = results: todos:
        if builtins.length todos == 0 then
          results
        else
          let input = builtins.head todos; in
          iter (results ++ [ input ]) ((builtins.tail todos) ++ input.buildInputs)
      ;
    in
    iter [ ] inputs
  ;
  depFlags = deps:
    builtins.concatStringsSep " " (map
      (dep: "-Xlinker -rpath -Xlinker ${dep}/lib -L ${dep}/lib -I ${dep}/swift -Xcc -I${dep}/swift")
      (flattenBuildInputs deps));
  depSwiftModules = deps:
    builtins.concatStringsSep " " (map
      (dep: "${dep}/swift/${dep.pname}.swiftmodule")
      (flattenBuildInputs deps));
  depLibs = deps: builtins.concatStringsSep " " (map (d: "${d}/lib/lib${d.pname}.so") deps);
  phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
  defaultInstallPhase = ''
    mv ${dirs.build} $out
  '';
  dirs = {
    build = "build";
    bin = "${dirs.build}/bin";
    lib = "${dirs.build}/lib";
    include = "${dirs.build}/swift";
    tmp = "tmp";
  };
in
rec {
  swiftPlatforms = [ "x86_64-linux" ];

  mkDynamicCLibrary =
    pkgs:
    { version
    , src
    , target
    , srcRoot ? "Sources/${target}"
    , buildInputs ? [ ]
    , patchPhase ? ""
    , installPhase ? defaultInstallPhase
    , extraCompilerFlags ? ""
    ,
    }:
    let
      includeSourceDir = "${srcRoot}/include";
      libName = "lib${target}.so";
    in
    pkgs.stdenv.mkDerivation rec {
      inherit src version patchPhase phases installPhase buildInputs;
      pname = target;
      nativeBuildInputs = [ pkgs.swift ];
      buildPhase = ''
        mkdir ${dirs.build}
        mkdir ${dirs.lib}
        mkdir ${dirs.tmp}
        for cFile in $(find ${srcRoot} -name "*.c"); do
          clang \
            -I${includeSourceDir} \
            -O3 \
            -DNDEBUG \
            -fPIC \
            -MD \
            -MT ${dirs.tmp}/$(basename $cFile).o \
            -MF ${dirs.tmp}/$(basename $cFile).o.d \
            -o ${dirs.tmp}/$(basename $cFile).o \
            -c $cFile \
            ${extraCompilerFlags}
        done

        cp -r ${includeSourceDir} ${dirs.include}

        clang \
          -fPIC \
          -O3 \
          -DNDEBUG \
          -shared \
          -Wl,-soname,${libName} \
          -o ${dirs.lib}/${libName} \
          ${dirs.tmp}/*.o \
          ${extraCompilerFlags} \
          ${depLibs buildInputs}
      '';
    };

  mkDynamicLibrary =
    pkgs:
    { version
    , src
    , target
    , srcRoot ? "Sources/${target}"
    , buildInputs ? [ ]
    , patchPhase ? ""
    , installPhase ? defaultInstallPhase
    , extraCompilerFlags ? ""
    ,
    }:
    let
      libName = "lib${target}.so";
    in
    pkgs.stdenv.mkDerivation rec {
      inherit src version patchPhase phases installPhase buildInputs;
      pname = target;
      nativeBuildInputs = [ pkgs.swift ];
      buildPhase = ''
        mkdir ${dirs.build}
        mkdir ${dirs.include}
        mkdir ${dirs.lib}
        swiftc \
          -emit-library \
          -module-name ${target} \
          -module-link-name ${target} \
          -emit-module \
          -emit-module-path "${dirs.include}/${target}.swiftmodule" \
          -emit-dependencies \
          -DSWIFT_PACKAGE \
          -O \
          -enable-testing \
          -Xlinker -soname -Xlinker ${libName} \
          -Xlinker -rpath -Xlinker ${dirs.lib} \
          ${depFlags buildInputs} \
          -o ${dirs.lib}/${libName} \
          ${extraCompilerFlags} \
          $(find ${srcRoot} -name '*.swift') \
          ${depSwiftModules buildInputs} \
          ${depLibs buildInputs}
        echo ${depSwiftModules buildInputs}
      '';
    };

  mkExecutable =
    pkgs:
    { version
    , src
    , target
    , srcRoot ? "Sources/${target}"
    , buildInputs ? [ ]
    , patchPhase ? ""
    , installPhase ? defaultInstallPhase
    , extraCompilerFlags ? ""
    ,
    }:
    pkgs.stdenv.mkDerivation rec {
      inherit src version patchPhase phases installPhase buildInputs;
      pname = target;
      nativeBuildInputs = [ pkgs.swift ];
      buildPhase = ''
        mkdir ${dirs.build}
        mkdir ${dirs.bin}
        swiftc \
          -emit-executable \
          ${depFlags buildInputs} \
          -o ${dirs.bin}/${target} \
          ${extraCompilerFlags} \
          $(find ${srcRoot} -name '*.swift') \
          ${depSwiftModules buildInputs} \
          ${depLibs buildInputs}
        echo "${depSwiftModules buildInputs}"
      '';
    };
}
