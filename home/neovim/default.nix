{ config, pkgs, lib, ... }:
let
  pluginDrv2linkFarmEntry = pdrv: {
    name = "${pdrv.pluginName or (lib.getName pdrv)}";
    path = pdrv;
  };
  buildVimPlugin = name-src: (
    (pkgs.vimUtils.buildVimPlugin name-src).overrideAttrs (_: {
      # ignore the `vimplugin-` prefix set by `pkgs.vimUtils.buildVimPlugin`
      pluginName = name-src.name;
    })
  );
in
let
  mellifluous-nvim = (buildVimPlugin {
    name = "mellifluous.nvim";
    src = pkgs.fetchFromGitHub {
      owner = "ramojus";
      repo = "mellifluous.nvim";
      rev = "9948359e1536b4171615f7280e61e17620e3fd45";
      sha256 = "QN9HsTlxV0vL7NuKT6TWtP2iODyIVROOd+GFR/mW7vQ=";
    };
  });
  leanAbbreviationsLuaTable =
    let
      leanAbbreviations = pkgs.stdenv.mkDerivation {
        name = "lean-abbreviations";
        src = pkgs.fetchFromGitHub {
          owner = "leanprover";
          repo = "vscode-lean4";
          rev = "294a803de45f5302865d84c44783aeb4e18068bb";
          sha256 = "vWMSIZ6dUNkpXI0INg2BEKQdnEjIYPVMNrrtz4LCzJ0=";
        };
        nativeBuildInputs = [ pkgs.jq ];
        dontUnpack = true;
        buildPhase = ''
          ${pkgs.jq}/bin/jq -r '
            to_entries
            | map("[" + ("\\"+.key | @json) + "]=" + (.value | @json))
            | "{" + join(",") + "}"
          ' < $src/lean4-unicode-input/src/abbreviations.json > LuaTable
        '';
        installPhase = ''
          mkdir -p $out
          cp LuaTable $out/
        '';
      };
    in
    lib.strings.trim (builtins.readFile "${leanAbbreviations}/LuaTable");
in
let
  plugins = with pkgs.vimPlugins; [
    blink-cmp
    cmp-buffer
    cmp-nvim-lsp
    cmp-nvim-lsp-signature-help
    cmp-path
    gitsigns-nvim
    lualine-nvim
    (luasnip.overrideAttrs (_: { pluginName = "LuaSnip"; }))
    mellifluous-nvim
    mini-icons
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
    bash-language-server
    haskell-language-server
    lean4
    typescript-language-server
  ];
  treesitterParsersSelector = tp: with tp; [
    nix
    lua
    rust
    go
    bash
    typescript
    javascript
  ];
in
let
  pluginsDir = pkgs.linkFarm "plugins-dir" (
    map pluginDrv2linkFarmEntry plugins
  );
  nvimTreesitterParsers =
    let
      nvimTreesitterDependencies = pkgs.symlinkJoin {
        name = "nvim-treesitter-dependencies";
        paths = (pkgs.vimPlugins.nvim-treesitter.withPlugins treesitterParsersSelector).dependencies;
      };
    in
    "${nvimTreesitterDependencies}/parser";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    extraPackages = lsps;
    plugins = [pkgs.vimPlugins.lazy-nvim];
    initLua = builtins.replaceStrings
      ["{{pluginsDir}}" "LEAN_ABBREVIATIONS = {}"]
      ["${pluginsDir}"  "LEAN_ABBREVIATIONS = ${leanAbbreviationsLuaTable}"]
      (builtins.readFile ./nvim/init.lua);
  };

  home.file = {
    # the installed parsers (selected by `treesitterParsersSelector`)
    "${config.xdg.dataHome}/nvim/site/parser".source = "${nvimTreesitterParsers}";
    # nvim-treesitter's builtin, all supported queries (https://github.com/nvim-treesitter/nvim-treesitter/tree/main/runtime/queries)
    "${config.xdg.dataHome}/nvim/site/queries".source = "${pluginsDir}/nvim-treesitter/runtime/queries";
  };
}
