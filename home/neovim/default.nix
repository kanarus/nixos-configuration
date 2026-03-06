{ config, pkgs, lib, ... }:
let
  mkPluginsDir =
    let
      drv2linkFarmEntry = drv: {
        name = "${drv.pluginName or (lib.getName drv)}";
        path = drv;
      };
    in
    plugins: pkgs.linkFarm "plugins-dir" (
      builtins.map drv2linkFarmEntry plugins
    );
  plugins = with pkgs.vimPlugins; [
    blink-cmp
    cmp-buffer
    cmp-nvim-lsp
    cmp-nvim-lsp-signature-help
    cmp-path
    gitsigns-nvim
    lualine-nvim
    (luasnip.overrideAttrs (_: { pluginName = "LuaSnip"; }))
    nvim-autopairs
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

  # home.file = {
  #   "${config.xdg.configHome}/nvim" = {
  #     source = ./nvim;
  #     recursive = true;
  #   };
  # };
}
