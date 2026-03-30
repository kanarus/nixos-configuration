{ config, pkgs, inputs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  imports = [
    ./browser
    ./desktop
    ./direnv
    ./ghostty
    ./git
    ./i18n
    ./neovim
    ./util
    ./zsh
  ];
}
