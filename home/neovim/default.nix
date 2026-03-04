{ config, pkgs, lib, ... }:
let
  mkPluginsDir =
    let
      drv2LinkFarmEntry = drv: {
        name = "${lib.getName drv}";
        path = drv;
      };
    in
    plugins: pkgs.linkFarm "plugins-dir" (
      builtins.map drv2LinkFarmEntry plugins
    );
  plugins = with pkgs.vimPlugins; [
    cmp-buffer
    cmp-nvim-lsp
    cmp-nvim-signature-help
    cmp-path
    gitsigns-nvim
    lualine-nvim
    nvim-autopairs
    nvim-cmp
    nvim-lspconfig
    nvim-treesitter
    oil-nvim
  ];
  lsps = with pkgs; [
    nixd
    lua-language-server
    gopls
    rust-analyzer
  ];
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraPackages = lsps;
    plugins = [pkgs.vimPlugins.lazy-nvim];
    initLua = builtins.replaceStrings
      ["{{pluginsDir}}"]
      ["${mkPluginsDir plugins}"]
      (builtins.readFile ./nvim/init.lua);
  };

  home.file = {
    "${config.xdg.configHome}/nvim" = {
      source = ./nvim;
      resursive = true;
    };
  };
}
