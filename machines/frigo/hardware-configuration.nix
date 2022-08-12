{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd = {
      includeDefaultModules = false;
      kernelModules = [ "vc4" ];
      availableKernelModules = [ "usbhid" "usb_storage" "vc4" "bcm2835_dma" "i2c_bcm2835" ];
    };
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
        firmwareConfig = ''
          arm_64bit=1
          lcd_rotate=2
          [pi4]
          arm_boost=1
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypifw
  ];

  hardware = {
    enableRedistributableFirmware = true;
    deviceTree = {
      filter = lib.mkForce "*rpi*.dtb";
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
          name = "audio-on-overlay";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2711";
              fragment@0 {
                target = <&audio>;
                __overlay__ {
                  status = "okay";
                };
              };
            };
          '';
        }
        {
          name = "bcm2708";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2708";
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
          name = "bcm2709";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,2709";
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
          name = "bcm2710";
          dtsText = ''
            /dts-v1/;
            /plugin/;
            / {
              compatible = "brcm,bcm2710";
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
      ];
    };

    firmware = [
      pkgs.wireless-regdb
      pkgs.raspberrypiWirelessFirmware
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
      options = [ "noatime" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  nix.settings.max-jobs = lib.mkDefault 4;
}
