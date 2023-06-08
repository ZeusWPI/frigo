{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  nixpkgs.overlays = [
    (self: super: {
      # Avoid building zfs-enabled kernel
      zfs = super.zfs.overrideAttrs (_: {
        meta.platforms = [ ];
      });
    })
    # Allow missing firmware in kernel
    (self: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  sdImage.compressImage = false;

  hardware = {
    raspberry-pi."4" = {
      backlight.enable = true;
      touch-ft5406.enable = true;
    };
    deviceTree = {
      filter = "bcm2711-rpi-4-b.dtb";
overlays = [
        # Equivalent to:
        # https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/cma-overlay.dts
        {
          name = "rpi4-cma-overlay";
          dtsText = ''
            // SPDX-License-Identifier: GPL-2.0
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@0 {
                target = <&cma>;
                __overlay__ {
                  size = <(512 * 1024 * 1024)>;
                };
              };
            };
          '';
        }
        # Equivalent to:
        # https://github.com/raspberrypi/linux/blob/rpi-6.1.y/arch/arm/boot/dts/overlays/vc4-fkms-v3d-overlay.dts
        {
          name = "rpi4-vc4-fkms-v3d-overlay";
          dtsText = ''
            // SPDX-License-Identifier: GPL-2.0
            /dts-v1/;
            /plugin/;

            / {
              compatible = "brcm,bcm2711";

              fragment@1 {
                target = <&fb>;
                __overlay__ {
                  status = "disabled";
                };
              };

              fragment@2 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };

              fragment@3 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
      ];
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nix.settings.max-jobs = lib.mkDefault 4;
}
