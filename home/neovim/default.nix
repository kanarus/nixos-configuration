{ config, pkgs, lib, ... }:
let
  pluginDrv2linkFarmEntry = pdrv: {
    name = "${pdrv.pluginName or (lib.getName pdrv)}";
    path = pdrv;
  };
  buildVimPlugin = name-src: (
    (pkgs.vimUtils.buildVimPlugin name-src).overrideAttrs (_: {
      # ignore the `vimplugin-` prefix set by `pkgs.buildVimPlugin`
      pluginName = name-src.name;
    })
  );
in
let
  mellifluous = (buildVimPlugin {
    name = "mellifluous.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "ramojus";
      repo = "mellifluous.nvim";
      rev = "9948359e1536b4171615f7280e61e17620e3fd45";
      sha256 = "QN9HsTlxV0vL7NuKT6TWtP2iODyIVROOd+GFR/mW7vQ=";
    };
  });
in
let
  lsps = with pkgs; [
    nixd
    lua-language-server
    gopls
    rust-analyzer
  ];
  nvimTreesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    treesitterPlugins: with treesitterPlugins; [
      nix
      lua
      rust
      go
    ]
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
    mellifluous
  ];
in
{
  programs.neovim = let
    pluginsDir = pkgs.linkFarm "plugins-dir" (
      map pluginDrv2linkFarmEntry plugins
    );
  in {
    enable = true;
    defaultEditor = true;
    extraPackages = lsps;
    plugins = [pkgs.vimPlugins.lazy-nvim];
    initLua = builtins.replaceStrings
      ["{{pluginsDir}}"]
      ["${pluginsDir}"]
      (builtins.readFile ./nvim/init.lua);
  };

  home.file = let
    nvimTreesitterDependencies = pkgs.symlinkJoin {
      name = "nvim-treesitter-dependencies";
      paths = nvimTreesitter.dependencies;
    };
  in {
    "${config.xdg.dataHome}/nvim/site/parser".source = "${nvimTreesitterDependencies}/parser";
    "${config.xdg.dataHome}/nvim/site/queries".source = "${nvimTreesitterDependencies}/queries";
  };
}
