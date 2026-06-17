{
  description = "keyb-viewer host build environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      forAll = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in {
      devShells = forAll (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = [
              pkgs.hidapi
              pkgs.pkg-config
              pkgs.quickshell
              (pkgs.python3.withPackages (ps: with ps; [ keymap-drawer ]))
            ];
          };
        });
    };
}
