{ username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
  imports = [
    ./claudecode
    ./browser
    ./desktop
    ./direnv
    ./ghostty
    ./git
    ./i18n
    ./neovim
    ./podman
    ./util
    ./zsh
  ];
}
