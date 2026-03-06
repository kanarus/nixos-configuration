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
    swayidle
    swaylock
    xwayland-satellite
  ];

  home.file = {
    "${config.xdg.configHome}/niri/config.kdl".source = ./niri-config.kdl;
    "${config.xdg.configHome}/waybar/style.css".source = ./waybar-style.css;
    "${config.xdg.configHome}/waybar/config.jsonc".source = ./waybar-config.jsonc;
    "${config.xdg.configHome}/waybar/powermenu.xml".source = ./waybar-powermenu.xml;
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
    iconTheme = gtkIconTheme;
    cursorTheme = gtkCursorTheme;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-kde
    ];
    config."niri" = {
      default = [ "kde" ];
    };
  };
}
