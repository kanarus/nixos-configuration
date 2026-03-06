{ pkgs, ... }: {
  home.packages = with pkgs; [
    gh
  ];

  programs.git = {
    enable = true;
    ignores = [
      ".direnv/"
      ".envrc"
      "flake.nix"
      "flake.lock"
    ];
    settings = {
      user = {
        name = "kanarus";
        email = "mail@kanarus.dev";
        signingKey = "5623D3EF85F1D635";
      };
      commit = {
        gpgSign = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  programs.gpg = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 3600;
    maxCacheTtl = 7200;
    pinentry.package = pkgs.pinentry-gnome3;
  };
}
