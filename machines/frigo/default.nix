{ lib, config, pkgs, modulesPath, ... }:
let
  adminUser = "zeus";
  kioskUser = "kiosk";
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgJTRCWS9rKQ5g0226IxoeCs74CERdggA0YruAdtlYY" # rien
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJY5nXR/V6wcMRxugD7GTOF8kwfGnAT2CRuJ2Qi60vsm" # chvp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgQgerwZXVnVBCfwtWW6m0wg4P4CsrQ6DkjJ61oC6LJ" # redfast00
  ];
  stateVersion = "22.11";
  browser = pkgs.firefox;
  autostart = ''
    #!${pkgs.bash}/bin/bash
    # End all lines with '&' to not halt startup script execution

    # https://developer.mozilla.org/en-US/docs/Mozilla/Command_Line_Options
    firefox --kiosk https://tap.zeus.gent/ &
  '';
in {
  imports =
    [
      ./hardware-configuration.nix
    ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Brussels";

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  users.users.${ adminUser } = {
    isNormalUser = true;
    group = adminUser;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  users.users.${ kioskUser } = {
    isNormalUser = true;
    group = kioskUser;
  };

  users.groups.${ adminUser } = {};
  users.groups.${ kioskUser } = {};

  home-manager.users.${ adminUser } = { pkgs, ... }: {
    home.stateVersion =  stateVersion;
    programs.bash = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    acpi
    fd
    file
    jq
    lsof
    pciutils
    ripgrep
    strace
    unzip
    wget
    zip
    dnsutils
    libinput
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
        experimental-features = nix-command flakes
    '';
  };

  services.openssh = {
    enable = true;
    permitRootLogin = (lib.mkForce "prohibit-password");
    kbdInteractiveAuthentication = false;
  };

  networking = {
    hostName = "frigo";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    timeServers = [
      "ntp.ugent.be"
    ];
  };

  #services.cage = {
  #  user = kioskUser;
  #  program = "${pkgs.firefox}/bin/firefox --kiosk https://tap.zeus.gent";
  #  enable = true;
  #};

  services.xserver = {
    enable = true;
    libinput.enable = true;
    displayManager = {
      lightdm.enable = true;
      autoLogin = {
        enable = true;
        user = adminUser;
      };
    };
    windowManager.openbox.enable = true;
    displayManager.defaultSession = "none+openbox";
    videoDrivers = [ "fbdev" ];
  };


  home-manager.users.${ kioskUser } = { pkgs, ... }: {
    home.stateVersion =  stateVersion;
    xdg.configFile."openbox/autostart".source = pkgs.writeScript "autostart" autostart;
  };

  # Don't change this.
  # See https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = stateVersion;
}

