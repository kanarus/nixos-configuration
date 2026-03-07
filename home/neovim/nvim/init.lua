vim.wo.number = true
vim.wo.signcolumn = "yes"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.expandtab = true
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4

vim.o.clipboard = "unnamedplus"
vim.o.completeopt = "menuone,noselect"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.hlsearch = true
vim.o.confirm = true

require("lazy").setup({
  {
    "saghen/blink.cmp",
    dependencies = { "L3MON4D3/LuaSnip" },
    opts_extend = { "sources.default" },
    opts = {
      sources = {
        default = function()
          local sources = { "path", "snippets" }
          if #(vim.lsp.get_clients({ bufnr = 0 })) > 0 then
		  print("[blink] lsp client detected: " .. vim.lsp.get_clients({ bufnr = 0 })[1].name)
	          table.insert(sources, "lsp")
	        else
	          table.insert(sources, "buffer")
	        end
	        return sources
   	    end,
      },
      fuzzy = {
        implementation = "rust",
        prebuilt_binaries = { download = false },
      },
      keymap = {
        preset = "none",
	      ["<Tab>"]   = { "select_next", "fallback" },
	      ["<C-Tab>"] = { "select_prev", "fallback" },
	      ["<CR>"]    = { "accept", "fallback" },
	      ["<Down>"]  = { "scroll_documentation_up", "fallback" },
	      ["<Up>"]    = { "scroll_documentation_down", "fallback" },
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
    	nmap("D",  vim.diagnostic.open_float, "open floating diagnostic message")
        nmap("rn", vim.lsp.buf.rename,        "[R]e[n]ame")
        nmap("gd", vim.lsp.buf.definition,    "[G]oto Definition")
        nmap("K",  vim.lsp.buf.hover,         "hover documentation")
      end
      local capabilities = require("blink.cmp").get_lsp_capabilities()
      local lspconfig = require("lspconfig")
      for _, lsname in ipairs({
        "nixd",
        "lua_ls",
        "gopls",
        "rust_analyzer"
      }) do
        lspconfig[lsname].setup({
          on_attach = on_attach,
          capabilities = capabilities
        })
      end
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
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
  {
    "ramokus/mellifluous.nvim",
    lazy = false,
    config = function()
      require("mellifluous").setup({})
      vim.cmd("colorscheme mellifluous")
    end,
  },
}, {
  lockfile = "", -- don't generate lazy-lock.json, leave the version control to nix
  install = {
    missing = false, -- skip auso-installing plugins on startup
  },
  defaults = {
    lazy = true,
  },
  dev = {
    path = "{{pluginsDir}}", -- replaced by ~/nixos-config/home/neovim/default.nix
    patterns = { "." },
    fallback = false,
  },
})
