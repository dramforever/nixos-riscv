{
  inputs = {
    nixpkgs.url = "github:NickCao/nixpkgs/riscv";
  };
  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      unmatched = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          ({ pkgs, lib, ... }: {
            nixpkgs = {
              crossSystem.config = "riscv64-unknown-linux-gnu";
              config.allowUnsupportedSystem = true;
            };
            boot.loader = {
              grub.enable = false;
              generic-extlinux-compatible.enable = true;
            };
            fileSystems."/".device = "fake";
          })
        ];
      };
    };
  };
}