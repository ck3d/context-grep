{
  description = "context-grep: search for regex patterns within comments and return surrounding code context";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    crane.url = "github:ipetkov/crane";
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
    }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs supportedSystems;

      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    {
      overlays.default = import ./overlay.nix;
      overlays.crane = final: prev: {
        craneLib = crane.mkLib final;
      };

      legacyPackages = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues self.overlays;
        }
      );

      packages = forAllSystems (system: self.legacyPackages.${system}.context-grep);

      checks = forAllSystems (
        system:
        let
          packages = lib.mapAttrs' (n: lib.nameValuePair "package-${n}") self.packages.${system};
          pkgDevShells = lib.mapAttrs' (n: pkg: lib.nameValuePair "package-${n}-devShell" pkg.devShell) (
            lib.filterAttrs (n: pkg: pkg ? devShell) self.packages.${system}
          );
          pkgTests = lib.concatMapAttrs (
            n: pkg:
            lib.mapAttrs' (c: checkPkg: lib.nameValuePair "package-${n}-tests-${c}" checkPkg) (
              pkg.passthru.tests or { }
            )
          ) self.packages.${system};
          devShells = lib.mapAttrs' (n: lib.nameValuePair "devShell-${n}") self.devShells.${system} or { };
        in
        packages
        // pkgDevShells
        // pkgTests
        // devShells
        // {
          format = self.legacyPackages.${system}.runCommandLocal "format" { } ''
            ${lib.getExe self.formatter.${system}} --ci ${self}
            touch $out
          '';
        }
      );

      formatter = forAllSystems (system: self.legacyPackages.${system}.nixfmt-tree);
    };
}
