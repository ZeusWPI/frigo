{ lib, config, pkgs, ... }:
let
  kioskUser = "kiosk";
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICgJTRCWS9rKQ5g0226IxoeCs74CERdggA0YruAdtlYY" # rien
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJY5nXR/V6wcMRxugD7GTOF8kwfGnAT2CRuJ2Qi60vsm" # chvp
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGgQgerwZXVnVBCfwtWW6m0wg4P4CsrQ6DkjJ61oC6LJ" # redfast00
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIB5ifsYCLU1oP4wjYPKgF0Jc53CzdbJxwiOQdGXFEaUPAAAABHNzaDo=" # xerbalind
    "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIIH33pRp93TOK5OyidgYVYtWBNKawKFzUilOA7Nb2NWzAAAABHNzaDo=" # mstrypst
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
          authProtocols = [ "WPA-PSK-SHA256" ];
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
      end0 = {
        enable = true;
        DHCP = "yes";
        matchConfig = { Name = "end0"; };
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

  systemd.services.socat-port-forward = {
    enable = true;
    description = "socat port forward 0.0.0.0:1884 -> koin:1884";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:1884,fork,reuseaddr TCP:192.168.0.12:1884";
      Restart = "always";
      User = "root";
    };
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

