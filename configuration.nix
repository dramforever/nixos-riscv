{ config, pkgs, lib, modulesPath, ... }:

{
  disabledModules = [ "profiles/all-hardware.nix" ];
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };
  boot.initrd.kernelModules = [ "nvme" "mmc_block" "mmc_spi" "spi_sifive" "spi_nor" "uas" "sdhci_pci" ];
  boot.kernelParams = [ "console=ttySIF0" "console=ttySIF1" "loglevel=6" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPatches = map (patch: { name = patch; patch = "${pkgs.meta-sifive}/recipes-kernel/linux/files/${patch}"; }) [
    "0001-riscv-sifive-fu740-cpu-1-2-3-4-set-compatible-to-sif.patch"
    "0002-riscv-sifive-unmatched-update-regulators-values.patch"
    "0003-riscv-sifive-unmatched-define-PWM-LEDs.patch"
    "0004-riscv-sifive-unmatched-add-gpio-poweroff-node.patch"
    "0005-SiFive-HiFive-Unleashed-Add-PWM-LEDs-D1-D2-D3-D4.patch"
    "0006-riscv-sifive-unleashed-define-opp-table-cpufreq.patch"
  ] ++ [{
    name = "sifive";
    patch = null;
    extraConfig = ''
      SOC_SIFIVE y
      PCIE_FU740 y
      PWM_SIFIVE y
      EDAC_SIFIVE y
      SIFIVE_L2 y
      RISCV_ERRATA_ALTERNATIVE y
      ERRATA_SIFIVE y
      ERRATA_SIFIVE_CIP_453 y
      ERRATA_SIFIVE_CIP_1200 y
    '';
  }];
  services.udisks2.enable = false;
  security.polkit.enable = false;
  hardware.deviceTree.name = "sifive/hifive-unmatched-a00.dtb";
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/sayori-root";
      fsType = "ext4";
    };
  };
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };
  networking.hostName = "sayori";
  systemd.network = {
    enable = true;
    networks = {
      "eth0" = {
        matchConfig.MACAddress = "70:b3:d5:92:f9:dd";
        networkConfig.IPv6Token = "::740";
        DHCP = "yes";
      };
    };
  };

  nix = {
    trustedUsers = [ "root" "@wheel" ];
    extraOptions =
      let flakesEmpty = pkgs.writeText "flakes-empty.json" (builtins.toJSON { flakes = []; version = 2; });
      in ''
        flake-registry = ${flakesEmpty}
        experimental-features = nix-command flakes
      '';
  };

  users.users = {
    dram = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };

  security.sudo.extraRules = [
    {
      groups = [ "wheel" ];
      commands = [
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
