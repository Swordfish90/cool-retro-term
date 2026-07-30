{
  description = "cool-retro-term dev environment";

  inputs.nixpkgs.url = "flake:nixpkgs";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          qtEnv = pkgs.qt6.env "cool-retro-term-qt" [
            pkgs.qt6.qtbase
            pkgs.qt6.qtdeclarative
            pkgs.qt6.qt5compat
            pkgs.qt6.qtshadertools
          ];
        in {
          default = pkgs.mkShell {
            packages = [ qtEnv pkgs.qt6.qtbase.dev ] ++ pkgs.lib.optional pkgs.stdenv.isDarwin pkgs.libiconv;
          };
        });
    };
}
