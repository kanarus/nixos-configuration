{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sddm.nix
  ];

  system.stateVersion = "25.11";

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than +7";
  };

  services.tlp = {
    enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    wifi = {
      backend = "iwd";
    };
  };

  systemd.services = {
    "router-arp-keepalive" = let
      wifiInterfaceName = "wlan0";
      routerIP = "100.64.1.1";
      arpingIntervalSec = 2;
    in {
      description = "Keep router ARP cache alive to bypass Intel Wi-Fi GTK drop bug";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do ${pkgs.iputils}/bin/arping -q -c 1 -I ${wifiInterfaceName} ${routerIP}; sleep ${toString arpingIntervalSec}; done'";
      };
    };
  };

  hardware.graphics.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  time.timeZone = "Asia/Tokyo";

  security.sudo = {
    enable = true;
    configFile = ''
      Defaults timestamp_timeout=60
    '';
  };

  i18n.defaultLocale = "en_US.UTF-8";
  console.font = "Lat2-Terminus16";
  console.useXkbConfig = true; # use xkb.options in tty.

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
  ];

  programs.nix-ld = {
    enable = true;
  };

  virtualisation.docker = {
    enable = true;
  };

  programs.ssh = {
    knownHosts = {
      "github.com" = {
        publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      };
    };
  };

  fonts = {
    packages = with pkgs; [
      monaspace
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-emoji-blob-bin
      udev-gothic
      udev-gothic-nf
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        monospace = [ "UDEV Gothic 35NF" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  services.keyd = {
    enable = true;
    keyboards = {
      default = {
        ids = [ "*" ];
        settings = {
          "main" = {
            capslock = "layer(control)";
          };
        };
      };
    };
  };

  programs.zsh.enable = true;
  users.users.kanarus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" ];
    shell = pkgs.zsh;
  };

  programs.niri = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "niri-patched";
      paths = [ pkgs.niri ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/niri --prefix LD_LIBRARY_PATH : "/run/opengl-driver/lib"
      '';
      passthru = {
        providedSessions = [ "niri" ];
      };
    };
  };
  programs.uwsm = {
    enable = true;
    waylandCompositors.niri = {
      prettyName = "Niri";
      comment = "Niri compositor managed by UWSM";
      binPath = "/run/current-system/sw/bin/niri";
      extraArgs = [ "--session" ];
    };
  };
}
