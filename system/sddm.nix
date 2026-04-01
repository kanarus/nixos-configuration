{ pkgs, ... }:
let
  customSddmTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "where-is-my-sddm-theme";
    version = "1.12.0";

    src = pkgs.fetchFromGitHub {
      owner = "stepanzubkov";
      repo = "where-is-my-sddm-theme";
      rev = "v1.12.0";
      hash = "sha256-+R0PX84SL2qH8rZMfk3tqkhGWPR6DpY1LgX9bifNYCg=";
    };

    installPhase = ''
      cp ${../assets/nix-wallpaper-gear.png} where_is_my_sddm_theme/background.png
      substituteInPlace where_is_my_sddm_theme/theme.conf \
        --replace 'background='                     'background=background.png' \
        --replace 'backgroundFill=#000000'          'backgroundFill=' \
        --replace 'font=monospace'                  'font="UDEV Gothic 35NF"' \
        --replace 'helpFont=monospace'              'helpFont="UDEV Gothic 35NF"' \
        --replace 'passwordInputCursorVisible=true' 'passwordInputCursorVisible=false' \
        --replace 'passwordInputWidth=0.5'          'passwordInputWidth=0.75' \
        --replace 'passwordInputRadius='            'passwordInputRadius=12' \
        --replace 'passwordInputBorderWidth=0'      'passwordInputBorderWidth=4' \
        --replace 'passwordInputBorderColor='       'passwordInputBorderColor=#e2eaff' \
        --replace 'passwordTextColor='              'passwordTextColor=#e2eaff' \
        --replace 'passwordFontSize=96'             'passwordFontSize=32'
      mkdir -p $out/share/sddm/themes
      cp -a where_is_my_sddm_theme $out/share/sddm/themes/
    '';
  };
in
{
  environment.systemPackages = [
    customSddmTheme
  ];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "where_is_my_sddm_theme";
    extraPackages = with pkgs; [
      kdePackages.qt5compat     # for QtGraphicalEffects
      kdePackages.qtdeclarative # for QtQuick
    ];
  };
}
