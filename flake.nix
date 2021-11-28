{
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/riscv";
  };
  outputs = { self, nixpkgs }: {
    legacyPackages.x86_64-linux =
      import nixpkgs {
        localSystem.config = "x86_64-unknown-linux-gnu";
        crossSystem.config = "riscv64-unknown-linux-gnu";
        overlays = [ (import ./overlay.nix) ];
      };

    nixosConfigurations = {
      sayori = nixpkgs.lib.nixosSystem {
        system = "riscv64-linux";

        modules = [
          ./configuration.nix
          { nixpkgs.pkgs = self.legacyPackages.x86_64-linux; }
        ];
      };
    };
  };
}
