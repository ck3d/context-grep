{
  description = "context-grep: search for regex patterns within comments and return surrounding code context";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
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

      legacyPackages = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );

      packages = forAllSystems (system: self.legacyPackages.${system}.context-grep);

      devShells = forAllSystems (
        system:
        let
          pkgs = self.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.jaq ];
          };
        }
      );
    };
}
