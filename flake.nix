{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        isLinux = system == "x86_64-linux";
        pkgs = if isLinux then nixpkgs.legacyPackages.${system} else nixpkgs-unstable.legacyPackages.${system};
        unstable = nixpkgs-unstable.legacyPackages.${system};

        makeLLVM = llvmPkgs: let
          filterFlags = flags: builtins.filter (f: !builtins.elem f ["trivialautovarinit" "shadowstack"]) (if builtins.isList flags then flags else []);

          safeStdenv =
            pkgs.stdenv
            // {
              mkDerivation = args:
                pkgs.stdenv.mkDerivation (
                  if builtins.isFunction args
                  then
                    (finalAttrs: let
                      res = args finalAttrs;
                    in
                      res
                      // {
                        hardeningEnable = filterFlags (res.hardeningEnable or []);
                        hardeningDisable = filterFlags (res.hardeningDisable or []);
                      })
                  else if builtins.isAttrs args
                  then
                    args
                    // {
                      hardeningEnable = filterFlags (args.hardeningEnable or []);
                      hardeningDisable = filterFlags (args.hardeningDisable or []);
                    }
                  else args
                );
            };
        in
          llvmPkgs.libllvm.override {
            stdenv = safeStdenv;
            cmake = pkgs.cmake;
            ninja = pkgs.ninja;
            python3 = pkgs.python3;
          };

        extraArgs = if isLinux then {darwinMinVersionHook = _: null;} else {};
      in {
        packages = rec {
          llvm_20 = pkgs.python3Packages.callPackage ./package.nix ({libllvm = makeLLVM unstable.llvmPackages_20;} // extraArgs);
          llvm_21 = pkgs.python3Packages.callPackage ./package.nix ({libllvm = makeLLVM unstable.llvmPackages_21;} // extraArgs);
          llvm_22 = pkgs.python3Packages.callPackage ./package.nix ({libllvm = makeLLVM unstable.llvmPackages_22;} // extraArgs);
          default = llvm_22;
        };

        formatter = pkgs.alejandra;
      }
    );
}
