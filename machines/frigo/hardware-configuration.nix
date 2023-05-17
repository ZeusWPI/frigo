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
    (final: super: {
      makeModulesClosure = x:
        super.makeModulesClosure (x // { allowMissing = true; });
    })
  ];

  sdImage.compressImage = false;

  boot = {
    tmpOnTmpfs = true;
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    initrd = {
      kernelModules = [ "vc4" ];
      availableKernelModules = [
        "usbhid"
        "usb_storage"
        "vc4"
        "bcm2835_dma"
        "i2c_bcm2835"
        "pcie_brcmstb"
        "reset-raspberrypi"
      ];
    };
    loader = {
      grub.enable = lib.mkDefault false;
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypifw
  ];

  hardware = {
    deviceTree = {
      filter = "bcm2711-rpi-*.dtb";
      overlays = [
        {
          name = "cma";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm";
              fragment@0 {
                target = <&cma>;
                __overlay__ {
                  size = <(512 * 1024 * 1024)>;
                };
              };
            };
          '';
        }
        {
          name = "bcm2711";
          dtsText = ''
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
                target = <&firmwarekms>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@3 {
                target = <&v3d>;
                __overlay__ {
                  status = "okay";
                };
              };
              fragment@4 {
                target = <&vc4>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "rpi-ft5406-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
            	compatible = "brcm,bcm2711";
            	fragment@0 {
            		target-path = "/soc/firmware";
            		__overlay__ {
            			ts: touchscreen {
            				compatible = "raspberrypi,firmware-ts";
            				touchscreen-size-x = <800>;
            				touchscreen-size-y = <480>;
            			};
            		};
            	};
            	__overrides__ {
            		touchscreen-size-x = <&ts>,"touchscreen-size-x:0";
            		touchscreen-size-y = <&ts>,"touchscreen-size-y:0";
            		touchscreen-inverted-x = <&ts>,"touchscreen-inverted-x?";
            		touchscreen-inverted-y = <&ts>,"touchscreen-inverted-y?";
            		touchscreen-swapped-x-y = <&ts>,"touchscreen-swapped-x-y?";
              };
            };
          '';
        }
        {
          name = "rpi4-cpu-revision";
          dtsText = ''
            /dts-v1/;
            /plugin/;

            / {
              compatible = "raspberrypi,4-model-b";

              fragment@0 {
                target-path = "/";
                __overlay__ {
                  system {
                    linux,revision = <0x00d03114>;
                  };
                };
              };
            };
          '';
        }
      ];
    };
    enableRedistributableFirmware = true;
    firmware = [
      pkgs.wireless-regdb
      pkgs.raspberrypiWirelessFirmware
    ];
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nix.settings.max-jobs = lib.mkDefault 4;
}
