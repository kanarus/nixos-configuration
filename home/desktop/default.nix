{ config, pkgs, ... }:
let
  gtkTheme = {
    package = pkgs.graphite-gtk-theme;
    name = "Graphite-Dark";
  };
  gtkCursorTheme = {
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-light";
    size = 24;
  };
  gtkIconTheme = {
    # create:
    # - snake_case symlink from each `fcitx-mozc*.svg`s
    # - `fcitx_mozc_hiragana.svg` symlink from `fcitx-mozc.svg`
    # for waybar's input method panel
    package = pkgs.qogir-icon-theme.overrideAttrs (oldAttrs: {
      preInstall = (oldAttrs.preInstall or "") + ''
        for f in $(find Papirus* -type f -name "fcitx-mozc*.svg"); do
          dir="$(dirname $f)"
          base="$(basename $f)"
          ln -sf "$base" "$dir/$(echo $base | tr '-' '_')"
          if [ "$base" = "fcitx-mozc.svg" ]; then
            ln -sf "$base" "$dir/fcitx_mozc_hiragana.svg"
          fi
        done
      '';
    });
    name = "Qogir-Dark";
  };
in
{
  home.packages = with pkgs; [
    niri
    waybar
    swaybg
    swayidle # working together with `programs.swaylock` below
    xwayland-satellite
  ];

  home.file = {
    "${config.xdg.configHome}/niri/config.kdl".source = ./niri-config.kdl;
    "${config.xdg.configHome}/waybar/style.css".source = ./waybar-style.css;
    "${config.xdg.configHome}/waybar/config.jsonc".source = ./waybar-config.jsonc;
    "${config.xdg.dataHome}/wallpaper/default.png".source = ../../assets/nix-wallpaper-gear.png;
  };

  home.pointerCursor = gtkCursorTheme // {
    enable = true;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    font.name = "Noto Sans CJK JP";
    colorScheme = "dark";
    theme = gtkTheme;
    gtk4.theme = gtkTheme;
    iconTheme = gtkIconTheme;
    cursorTheme = gtkCursorTheme;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
    ];
    config."niri" = {
      default = [ "gtk" ];
      "org.freedesktop.portal.FileChooser" = [ "gnome" ];
    };
  };

  programs.swaylock = {
    enable = true;
    settings = { # syncing with system/sddm.nix
      image = "${../../assets/nix-wallpaper-gear.png}";
      color = "e2eaff";
      font-size = 96;
      font = "UDEV Gothic 35NF";
      indicator-idle-visible = false;
      indicator-radius = 12;
      line-color = "e2eaff";
    };
  };

  services.mako = {
    enable = true;
    settings = {
      "font" = "UDEV Gothic 35NF";
      "background-color" = "#646464d6"; # rgba(100, 100, 100, 0.84)
      "text-color" = "#e2eaff";
      "border-radius" = 4;
      "icons" = 1;
      "default-timeout" = 3000;
    };
  };

  services.kanshi =
    let
      builtinMonitorName = "eDP-1";
      HDMIMonitorName = "DP-1";
      outputOf = monitorName: {
        criteria = monitorName;
        status = "enable";
      };
    in
  {
    enable = true;
    settings = [
      {
        profile = {
          name = "undocked";
          outputs = [
            (outputOf builtinMonitorName)
          ];
          exec = [
            "niri msg action focus-workspace 1"
          ];
        };
      }
      {
        profile = {
          name = "docked";
          outputs = [
            (outputOf builtinMonitorName)
            (outputOf HDMIMonitorName)
          ];
          exec = [
            "niri msg action focus-monitor ${HDMIMonitorName}"
          ];
        };
      }
    ];
  };
}
