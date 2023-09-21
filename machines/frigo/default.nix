{ lib, config, pkgs, ... }:
let
  kioskUser = "kiosk";
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgJTRCWS9rKQ5g0226IxoeCs74CERdggA0YruAdtlYY" # rien
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJY5nXR/V6wcMRxugD7GTOF8kwfGnAT2CRuJ2Qi60vsm" # chvp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgQgerwZXVnVBCfwtWW6m0wg4P4CsrQ6DkjJ61oC6LJ" # redfast00
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgMEJ9Z+wTwfwWBNzUSOD6TII1kziXAyVVEWWyCcOdE" # xerbalind
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
    timeServers = [ "ntp.ugent.be" ];
    wireless = {
      enable = true;
      environmentFile = config.age.secrets.wifi-env.path;
      interfaces = [ "wlan0" ];
      networks = {
        "Zeus WPI" = {
          psk = "@PSK_Zeus@";
          hidden = true;
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    networks = {
      wlan0 = {
        enable = true;
        DHCP = "yes";
        matchConfig = { Name = "wlan0"; };
        dhcpV4Config = { RouteMetric = 20; };
        ipv6AcceptRAConfig = { RouteMetric = 20; };
      };
      eth0 = {
        enable = true;
        DHCP = "yes";
        matchConfig = { Name = "eth0"; };
        dhcpV4Config = { RouteMetric = 10; };
        ipv6AcceptRAConfig = { RouteMetric = 10; };
      };
    };
    wait-online.anyInterface = true;
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

  age.secrets = {
    wifi-env.file = ../../secrets/wifi-env.age;
    url = {
      file = ../../secrets/url.age;
      owner = kioskUser;
    };
  };

  # Don't change this.
  # See https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = stateVersion;
}

