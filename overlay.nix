self: super:

{
  meta-sifive = super.fetchFromGitHub {
    owner = "sifive";
    repo = "meta-sifive";
    rev = "2021.10.00";
    sha256 = "sha256-TDlrAOOoK+3k/J1gDT1CkbxlfGfhSayZEzIjG1L3iPY=";
  };
  opensbi = super.stdenv.mkDerivation rec {
    pname = "opensbi";
    version = "0.9";
    src = super.fetchFromGitHub {
      owner = "riscv";
      repo = "opensbi";
      rev = "v${version}";
      sha256 = "sha256-W39R1RHsIM3yNwW/eukO+mPd9joPZLw+/XIJoH8agN8=";
    };
    patches = map (patch: "${self.meta-sifive}/recipes-bsp/opensbi/files/${patch}") [
      "0001-Makefile-Don-t-specify-mabi-or-march.patch"
    ];
    hardeningDisable = [ "all" ];
    makeFlags = [
      "PLATFORM=generic"
      "I=$(out)"
    ];
  };
  uboot = super.buildUBoot rec {
    version = "2022.01-rc2";
    src = super.fetchFromGitHub {
      owner = "u-boot";
      repo = "u-boot";
      rev = "v${version}";
      sha256 = "sha256-74jHYazqHguPnaYisr9qfafMukIU+5+jCoZ+jXvXEUg=";
    };
    defconfig = "sifive_unmatched_defconfig";
    extraPatches = map (patch: "${self.meta-sifive}/recipes-bsp/u-boot/files/riscv64/${patch}") [
      "0001-riscv-sifive-unleashed-support-compressed-images.patch"
      "0015-riscv-sifive-unmatched-leave-128MiB-for-ramdisk.patch"
      "0016-riscv-sifive-unmatched-disable-FDT-and-initrd-reloca.patch"
    ];
    extraMakeFlags = [
      "OPENSBI=${self.opensbi}/share/opensbi/lp64/generic/firmware/fw_dynamic.bin"
    ];
    extraConfig = ''
      CONFIG_FS_EXT4=y
      CONFIG_CMD_EXT4=y
    '';
    filesToInstall = [ "u-boot.itb" "spl/u-boot-spl.bin" ];
  };

  qemu-small = (super.qemu.override {
    alsaSupport = false;
    pulseSupport = false;
    sdlSupport = false;
    gtkSupport = false;
    vncSupport = false;
    smartcardSupport = false;
    spiceSupport = false;
    hostCpuTargets = [ "riscv64-softmmu" ];
    python = self.buildPackages.python3;
  }).overrideAttrs (old: {
    depsBuildBuild = (old.depsBuildBuild or []) ++ [ self.buildPackages.buildPackages.binutils self.buildPackages.stdenv.cc ];
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ self.buildPackages.perl ];
    configureFlags = (old.configureFlags or []) ++ [ "--disable-kvm" ];
    makeFlags = (old.makeFlags or []) ++ [ "CROSS_COMPILE=${self.stdenv.cc.targetPrefix}" ];
  });
}
