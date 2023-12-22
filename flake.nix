{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    nix-php-shell = {
      url = "github:loophp/nix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, systems, nix-php-shell }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import systems;
      perSystem = { self', system, pkgs, lib, ... }:
        let
          php = pkgs.api.buildPhpFromComposer { src = self; };
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              nix-php-shell.overlays.default
            ];
          };
          formatter = pkgs.nixpkgs-fmt;
          devShells = {
            default = pkgs.mkShell {
              packages = [
                pkgs.yamlfmt
                pkgs.symfony-cli
                pkgs.sqlite
                pkgs.dart-sass

                php
                php.packages.composer
              ];
            };
          };
        };
    };
}