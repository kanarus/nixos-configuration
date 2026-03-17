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
  treesitterQueriesLean = pkgs.stdenv.mkDerivation {
    name = "treesitter-queries-lean";
    src = pkgs.fetchFromGitHub {
      owner = "julian";
      repo = "lean.nvim";
      rev = "306d2d756c869c60887efdf0dd8d35d8b0e9a33c";
      sha256 = "qbKybfraFtAvFj2rJgX3fDP6GS4oTDqmDBKS3SsjxrQ=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out
      cp $src/queries/lean/*.scm $out/
    '';
  };
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
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.jq ];
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
  nvimTreesitter = (pkgs.vimPlugins.nvim-treesitter.withPlugins (
    _: with pkgs.tree-sitter-grammars; [
      tree-sitter-nix
      tree-sitter-lua
      tree-sitter-lean
      tree-sitter-rust
      tree-sitter-go
      tree-sitter-bash
      tree-sitter-typescript
      tree-sitter-javascript
    ]
  )).overrideAttrs (oldAttrs: {
    preInstall = (oldAttrs.preInstall or "") + ''
      ln -s ${treesitterQueriesLean} runtime/queries/lean
    '';
  });
  plugins =  with pkgs.vimPlugins; [
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
    oil-nvim
  ] ++ [
    nvimTreesitter
  ];
in
{
  programs.neovim =
    let
      pluginsDir = pkgs.linkFarm "plugins-dir" (
        map pluginDrv2linkFarmEntry plugins
      );
    in
    {
      enable = true;
      defaultEditor = true;
      extraPackages = lsps;
      plugins = [pkgs.vimPlugins.lazy-nvim];
      initLua = builtins.replaceStrings
        ["{{pluginsDir}}" "LEAN_ABBREVIATIONS = {}"]
        ["${pluginsDir}"  "LEAN_ABBREVIATIONS = ${leanAbbreviationsLuaTable}"]
        (builtins.readFile ./nvim/init.lua);
    };

  home.file =
    let
      nvimTreesitterDependencies = pkgs.symlinkJoin {
        name = "nvim-treesitter-dependencies";
        paths = nvimTreesitter.dependencies;
      };
    in
    {
      # the installed parsers (selected by `nvim-treesitter.withPlugins`)
      "${config.xdg.dataHome}/nvim/site/parser".source = "${nvimTreesitterDependencies}/parser";
      # nvim-treesitter's builtin, all supported queries (https://github.com/nvim-treesitter/nvim-treesitter/tree/main/runtime/queries)
      "${config.xdg.dataHome}/nvim/site/queries".source = "${nvimTreesitter}/runtime/queries";
    };
}
