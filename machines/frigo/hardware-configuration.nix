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
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
    ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
        firmwareConfig = ''
          dtoverlay=vc4-kms-v3d
          display_auto_detect=1
          [pi4]
          arm_boost=1
        '';
      };
    };
  };

  environment.systemPackages = with pkgs; [
    libraspberrypi
  ];

  hardware = {
    enableRedistributableFirmware = true;
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
