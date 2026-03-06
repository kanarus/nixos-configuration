{ config, pkgs, inputs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  imports = [
    ./chrome
    ./desktop
    ./direnv
    ./ghostty
    ./git
    ./helix
    ./i18n
    ./neovim
    ./util
    ./zsh
  ];
}
