# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./sddm.nix
  ];

  system.stateVersion = "25.11";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  hardware.graphics.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
  services.blueman.enable = true;

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

  services.qemuGuest.enable = true;
  # services.xserver.enable = true;

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
