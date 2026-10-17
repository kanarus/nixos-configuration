{ config, pkgs, ... }:
let
  gtkTheme = {
    package = pkgs.colloid-gtk-theme;
    name = "Colloid-Dark";
  };
  gtkCursorTheme = {
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-light";
    size = 24;
  };
  gtkIconTheme = {
    package = pkgs.colloid-icon-theme.overrideAttrs (old: {
      preInstall = (old.preInstall or "") + ''
        for size in src/status/*/; do
          for fcitx_mozc_icon in "$size"/fcitx-mozc*.svg; do
            kebab_case="$(basename $fcitx_mozc_icon)"
            snake_case="$(echo $kebab_case | tr '-' '_')"
            cp "$size/$kebab_case" "$size/$snake_case"
          done
          if [ -f "$size/fcitx-mozc.svg" ]; then
            cp "$size/fcitx-mozc.svg" "$size/fcitx_mozc_hiragana.svg"
            cp "$size/fcitx-mozc.svg" "$size/org.fcitx.Fcitx5.fcitx_mozc_hiragana.svg"
          fi
        done
      ''; # for latest fcitx5-mozc tray icon behavior (displayed on waybar in this system)
      dontFixup = true; # skip symlink deletion (for avoid postFixupPhase hanging)
    });
    name = "Colloid-Dark";
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

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gnome
      ];
      config."niri" = {
        default = [ "gtk" ];
        "org.freedesktop.portal.FileChooser" = [ "gnome" ];
      };
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };

  programs.swaylock = {
    enable = true;
    settings = { # syncing with system/sddm.nix
      no-unlock-indicator = true;
      image = "${../../assets/nix-wallpaper-gear.png}";
      font-size = 96;
      font = "UDEV Gothic 35NF";
      text-color = "e2eaff";
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
      HDMIMonitorName = "DP-3";
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
            "niri msg action move-workspace-to-monitor ${HDMIMonitorName}"
          ];
        };
      }
    ];
  };
}
