vim.wo.number = true
vim.wo.signcolumn = "yes"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.wrap = false
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.virtualedit:append("onemore")
vim.keymap.set("n", "<End>", "$l", { remap = true, silent = true })

vim.o.clipboard = "unnamedplus"
vim.o.completeopt = "menuone,noselect"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.hlsearch = true
vim.o.confirm = true
vim.o.scrolloff = 8
vim.o.sidescrolloff = 16
vim.o.sidescroll = 1

---@class LanguageConfig
---@field tabtospace integer|nil

---@type table<string, LanguageConfig>
LspconfigName_to_LanguageConfig = {
  ["nixd"]          = {tabtospace = 2},
  ["lua_ls"]        = {tabtospace = 2},
  ["gopls"]         = {tabtospace = nil},
  ["rust_analyzer"] = {tabtospace = 4},
  ["bashls"]        = {tabtospace = 2},
  ["hls"]           = {tabtospace = 2},
}

---@param config LanguageConfig
local applyLanguageConfig = function(config)
  if config.tabtospace ~= nil then
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = config.tabtospace
    vim.opt_local.softtabstop = config.tabtospace
    vim.opt_local.shiftwidth = config.tabtospace
  end
end

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
	    ["<Down>"]  = { "select_next", "fallback" },
	    ["<Up>"]    = { "select_prev", "fallback" },
	    ["<CR>"]    = { "accept", "fallback" },
	    ["<Tab>"]   = { "scroll_documentation_down", "fallback" },
	    ["<C-Tab>"] = { "scroll_documentation_up", "fallback" },
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
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "lsp_status" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
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
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })
      local languageconfig_augroup = vim.api.nvim_create_augroup("LanguageConfig", { clear = true })
      for lspconfigname, _ in pairs(LspconfigName_to_LanguageConfig) do
        vim.lsp.enable(lspconfigname);
        vim.api.nvim_create_autocmd("FileType", {
	  group = languageconfig_augroup,
          pattern = vim.lsp.config[lspconfigname].filetypes,
          callback = function() -- be careful of variables' scope over a `callback`
            local languageconfig = LspconfigName_to_LanguageConfig[lspconfigname]
            applyLanguageConfig(languageconfig)
          end,
        })
      end
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local nmap = function(keys, fn, desc)
            vim.keymap.set(
              "n",
              keys,
              fn,
              { buffer = args.buf, desc = "LSP: " .. desc }
            )
          end
          nmap("D",  vim.diagnostic.open_float, "open floating diagnostic message")
          nmap("rn", vim.lsp.buf.rename,        "[R]e[n]ame")
          nmap("gd", vim.lsp.buf.definition,    "[G]oto Definition")
        end
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
      require("nvim-treesitter").setup()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
        callback = function()
          pcall(vim.treesitter.start)
        end
      })
    end,
  },
  {
    "stevearc/oil.nvim",
    dependencies = { "nvim-mini/mini.icons" },
    lazy = false,
    config = function()
      require("mini.icons").setup({})
      require("oil").setup({
        skip_confirm_for_simple_edits = true,
        view_options = {
          -- show hidden files/directories, while hide `..`
          show_hidden = true,
          is_always_hidden = function(name, _)
            return name == ".."
          end
        },
      })
      vim.keymap.set("n", "o", "<CMD>Oil<CR>", { desc = ":[O]il" })
    end
  },
  {
    "ramokus/mellifluous.nvim",
    lazy = false,
    init = function() vim.cmd("colorscheme mellifluous") end,
    opts = {
      styles = {
        comments = { italic = false },
      },
    },
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
    path = "{{pluginsDir}}", -- replaced by ~/nixos-configuration/home/neovim/default.nix
    patterns = { "." },
    fallback = false,
  },
})
