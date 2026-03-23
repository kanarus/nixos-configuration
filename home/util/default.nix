{ pkgs, ... }: {
  home.packages = with pkgs; [
    yazi
    blueman
  ];
}
