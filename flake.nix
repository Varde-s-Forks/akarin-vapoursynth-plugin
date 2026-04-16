{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          llvm_20 = let lp = pkgs.llvmPackages_20; in pkgs.callPackage ./package.nix {inherit (lp) libllvm stdenv;};
          llvm_21 = let lp = pkgs.llvmPackages_21; in pkgs.callPackage ./package.nix {inherit (lp) libllvm stdenv;};
          llvm_22 = let lp = pkgs.llvmPackages_22; in pkgs.callPackage ./package.nix {inherit (lp) libllvm stdenv;};
          default = llvm_22;
        };

        formatter = pkgs.alejandra;
      }
    );
}
