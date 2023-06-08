{ lib, config, pkgs, ... }:
let
  kioskUser = "kiosk";
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgJTRCWS9rKQ5g0226IxoeCs74CERdggA0YruAdtlYY" # rien
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJY5nXR/V6wcMRxugD7GTOF8kwfGnAT2CRuJ2Qi60vsm" # chvp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgQgerwZXVnVBCfwtWW6m0wg4P4CsrQ6DkjJ61oC6LJ" # redfast00
  ];
  stateVersion = "22.11";
in
{
  imports = [ ./hardware-configuration.nix ];

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Brussels";

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  users.users.${kioskUser} = {
    isNormalUser = true;
    group = kioskUser;
  };

  users.groups.${kioskUser} = { };

  environment.systemPackages = with pkgs; [ xscreensaver ];

  nix.extraOptions = ''experimental-features = nix-command flakes'';

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = (lib.mkForce "prohibit-password");
      KbdInteractiveAuthentication = false;
    };
  };

  networking = {
    hostName = "frigo";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
    timeServers = [ "ntp.ugent.be" ];
  };

  services.xserver = {
    enable = true;
    libinput.enable = true;
    displayManager = {
      lightdm.enable = true;
      autoLogin = {
        enable = true;
        user = kioskUser;
      };
      xserverArgs = [ "-nocursor" ];
    };
    windowManager.openbox.enable = true;
    displayManager.defaultSession = "none+openbox";
  };


  home-manager.users.${kioskUser} = { pkgs, ... }: {
    home.stateVersion = stateVersion;
    home.file.".xscreensaver".source = ./xscreensaver-config;
    xdg.configFile."openbox/autostart".text = ''
      #!${pkgs.bash}/bin/bash
      # End all lines with '&' to not halt startup script execution

      ${pkgs.xscreensaver}/bin/xscreensaver --no-splash &
      ${pkgs.ungoogled-chromium}/bin/chromium --force-device-scale-factor=0.6 --kiosk $(cat ${config.age.secrets.url.path}) &
    '';
  };

  age.secrets.url = {
    file = ../../secrets/url.age;
    owner = kioskUser;
  };

  # Don't change this.
  # See https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = stateVersion;
}

