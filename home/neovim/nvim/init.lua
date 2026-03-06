require("lazy").setup({
  {
    "saghen/blink.cmp",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts_extend = { "sources.default" },
    opts = {
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = {
        implementation = "rust",
        prebuilt_binaris = { download = false },
      },
      keymap = {
        preset = "default",
      },
      completion = {
        documentation = {
          auto_show = true,
        },
      },
      appearance = {
        nerd_font_variant = "UDEV Gothic 35NF",
      },
      snippets = {
        preset = "luasnip",
      },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    opts = {
      on_attach = function(buf)
        vim.keymap.set(
          "n",
          "<leader>gph",
          require("gitsigns").prev_hunk,
          { buffer = buf, desc = "[G]oto [P]revious [H]unk" }
        )
        vim.keymap.set(
          "n",
          "<leader>gnh",
          require("gitsigns").next_hunk,
          { buffer = buf, desc = "[G]oto [N]ext [H]unk" }
        )
        vim.keymap.set(
          "n",
          "<leader>ph",
          require("gitsigns").preview_hunk,
          { buffer = buf, desc = "[P]review [H]unk" }
        )
      end,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        icons_enabled = true,
      }
    }
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup()
    end
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    event = { "BufNewFile", "BufReadPre" },
    opts = {
      lsnames = {
        "nixd",
        "lua-language-server",
        "gopls",
        "rust-analyzer"
      }
    },
    config = function()
      local on_attach = function(_, buf)
        local nmap = function(keys, fn, desc)
          vim.keymap.set(
            "n",
            keys,
            fn,
            { buffer = buf, desc = "LSP: " .. desc }
          )
        end
        nmap("rn", vim.lsp.buf.rename,     "[R]e[n]ame")
        nmap("gd", vim.lsp.buf.definition, "[G]oto Definition")
        nmap("K",  vim.lsp.buf.hover,      "hover documentation")
      end
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")
      for _, lsname in ipairs(opts.lsnames) do
        lspconfig[lsname].setup({
          on_attach = on_attach,
          capabilities = capabilities
        })
      end
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    opts = {
      default_file_explorer = true,
    }
  },
}, {
  lockfile = "", -- don't generate lazy-lock.json, leave the version control to nix
  defaults = {
    lazy = true,
  },
  dev = {
    path = "{{pluginsDir}}", -- replaced by ~/nixos-config/home/neovim/default.nix
    patterns = { "." },
    fallback = false,
  },
})
