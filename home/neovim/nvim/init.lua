---@return boolean
local function lsp_is_attached_for_current_buffer()
  return #(vim.lsp.get_clients({ bufnr = 0 })) > 0
end

local function ime_turn_off()
  os.execute("fcitx5-remote -s keyboard-us")
end

---@param str string
---@param sub string
---@return boolean
local function string_startswith(str, sub)
  return string.sub(str, 1, #sub) == sub
end

---@param str string
---@param sub string
---@return string
local function string_trimstart_ifmatch(str, sub)
  if string_startswith(str, sub) then
    return string.sub(str, 1 + #sub)
  else
    return str
  end
end

---NOTE: This is a makefhist, simple implementation; buggy for complex input
---@return string
local function string_replace(str, from, to)
  local escaped_from, _ = string.gsub(from, "%-", "%%-")
  local replaced, _ = string.gsub(str, escaped_from, to)
  return replaced
end

vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.signcolumn = "yes"

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.laststatus = 3
vim.opt.cmdheight = 0
vim.opt.showmode = false
vim.opt.guicursor = "n-v:block,i-c-ci-ve:ver25,r-cr:hor20,o:hor50"
vim.opt.backupcopy = "yes"

vim.o.clipboard = "unnamedplus"
vim.o.completeopt = "menuone,noselect"
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.termguicolors = true
vim.o.hlsearch = true
vim.o.confirm = true
vim.o.scroll = 10
vim.o.scrolloff = 5
vim.o.sidescroll = 1
vim.o.sidescrolloff = 16

vim.keymap.set("n", "<PageDown>", "10j", { silent = true })
vim.keymap.set("n", "<PageUp>",   "10k", { silent = true })
vim.keymap.set("n", "<C-Right>", "w", { silent = true })
vim.keymap.set("n", "<C-Left>",  "b", { silent = true })
vim.keymap.set("i", "<C-BS>", "<C-w>", { silent = true })
vim.keymap.set({ "n", "i" }, "<A-Right>", "<C-w>l", { silent = true })
vim.keymap.set({ "n", "i" }, "<A-Left>", "<C-w>h", { silent = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusGained" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() == "n" then
      ime_turn_off()
    end
  end
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  pattern = "*",
  nested = true,
  command = "silent! update",
})

vim.api.nvim_create_autocmd("User", {
  pattern = "GitSignUpdate",
  callback = function()
    require("lualine").refresh({ place = { "statusline" } })
  end
})

-- extension-to-filetype mapping for unsupported-by-default languages
vim.filetype.add({
  extension = {
    lean = "lean",
    typ  = "typst",
    kdl  = "kdl",
  }
})
-- lsp servers for unsupported-by-default languages
vim.lsp.config("lean", {
  cmd = { "lean", "--server" },
  filetypes = { "lean" },
})
vim.lsp.config("tinymist", {
  cmd = { "tinymist" },
  filetypes = { "typst" },
})

local NonOilBufReadPreAugroup = vim.api.nvim_create_augroup("NonOilBufReadPre", { clear = true })
vim.api.nvim_create_autocmd("BufReadPre", {
  group = NonOilBufReadPreAugroup,
  callback = function(args)
    if not string_startswith(args.file, "oil://") then
      vim.api.nvim_exec_autocmds("User", { pattern = "NonOilBufReadPre" })
      vim.api.nvim_clear_autocmds({ group = NonOilBufReadPreAugroup })
    end
  end,
})

---@class LanguageConfig
---@field filetypes string[]|nil
---@field lspconfigname string|nil
---@field lspconfigsettings table|nil
---@field tabtospace boolean|nil
---@field indentwidth integer|nil
---@field wrap boolean|nil

local LanguageConfigAugroup = vim.api.nvim_create_augroup("LanguageConfig", { clear = true })
---@param config LanguageConfig
--- NOTE: at least one of `filetypes` or `lspconfigname` MUST be non-nil.
local function applyLanguageConfig(config)
  if (not config.filetypes) and (not config.lspconfigname) then
    return
  end
  if config.lspconfigname ~= nil then
    if config.lspconfigsettings ~= nil then
      vim.lsp.config(config.lspconfigname, {
        settings = config.lspconfigsettings,
      })
    end
    vim.lsp.enable(config.lspconfigname)
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = LanguageConfigAugroup,
    pattern = config.filetypes or vim.lsp.config[config.lspconfigname].filetypes,
    callback = function()
      if config.tabtospace ~= nil then
        vim.opt_local.expandtab = config.tabtospace
        if not config.tabtospace then -- vim's default Tab handling:
          vim.opt_local.tabstop = 8
          vim.opt_local.softtabstop = 0
          vim.opt_local.shiftwidth = 0
        end
      end
      if config.indentwidth ~= nil then
        vim.opt_local.tabstop = config.indentwidth
        vim.opt_local.softtabstop = config.indentwidth
        vim.opt_local.shiftwidth = config.indentwidth
      end
      if config.wrap ~= nil then
        vim.opt_local.wrap = config.wrap
        vim.opt_local.linebreak = config.wrap
        vim.keymap.set('n', '<Up>', 'gk', { silent = true, buffer = true })
        vim.keymap.set('n', '<Down>', 'gj', { silent = true, buffer = true })
        vim.keymap.set('i', '<Up>', '<C-O>gk', { silent = true, buffer = true })
        vim.keymap.set('i', '<Down>', '<C-O>gj', { silent = true, buffer = true })
      end
    end,
  })
end
-- global fallback language config
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.wrap = false
vim.opt.linebreak = false

require("lazy").setup({
  {
    "saghen/blink.cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "L3MON4D3/LuaSnip" },
    opts = {
      sources = {
        default = function()
          local sources = {}
          if lsp_is_attached_for_current_buffer() then
            vim.lsp.config("*", {
              capabilities = require("blink.cmp").get_lsp_capabilities(),
            })
            table.insert(sources, "lsp")
          end
          table.insert(sources, "snippets")
          return sources
   	    end,
      },
      fuzzy = {
        implementation = "rust",
        prebuilt_binaries = { download = false },
      },
      keymap = {
        preset = "none",
        ["<Down>"]   = { "select_next", "fallback" },
	      ["<Up>"]     = { "select_prev", "fallback" },
	      ["<CR>"]     = { "accept", "fallback" },
	      ["<C-Down>"] = { "scroll_documentation_down", "fallback" },
	      ["<C-Up>"]   = { "scroll_documentation_up", "fallback" },
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
    "L3MON4D3/LuaSnip",
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("LeanAbbreviations", { clear = true }),
        pattern = { "lean" },
        once = true,
        callback = function()
          local ls = require("luasnip")
          ls.config.set_config({
            enable_auto_snippets = true,
            updateevents = "TextChanged,TextChangedI",
          })

          ---@type table<string, string>
          LEAN_ABBREVIATIONS = {} -- replaced by nixos-configuration/home/neovim/default.nix

          local snippets = {}
          for trigger, symbol in pairs(LEAN_ABBREVIATIONS) do
            table.insert(snippets, ls.snippet(
              { trig = trigger, desc = symbol },
              { ls.text_node(symbol) }
            ))
          end
          ls.add_snippets("lean", snippets)
        end
      })
    end
  },
  {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    opts = {},
  },
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufNewFile", "User NonOilBufReadPre" },
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
    lazy = false,
    dependencies = { "ramokus/mellifluous.nvim" },
    config = function()
      local theme = require("lualine.themes.auto")
      for _, mode in ipairs({ "normal", "insert", "replace", "visual", "command" }) do
        theme[mode].b.bg = "#e9e9e9"
        theme[mode].c.bg = "#f2f2f2"
      end
      require("lualine").setup({
        options = {
          theme = theme,
          icons_enabled = true,
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            function()
              -- * For a oil buffer, this is `oil://` followed by
              --   the absolute path of the directory with trailing slash,
              --   e.g. `oil:///home/username/dir/`
              --
              -- * For a file buffer out of nvim's CWD,
              --   this is the absolute path of it,
              --   e.g. `/home/username/dir/file.ext`
              -- 
              -- * For a file buffer in nvim's CWD,
              --   this is the relative path of it from the cwd,
              --   e.g. `file.ext`, `dir/file.ext`
              --   But occasionally (I don't know the condition) the absolute path is set.
              --   e.g. `/home/username/dir/file.ext`
              local p = vim.fn.expand("%")
              if string_startswith(p, "oil://") then
                local directory_abspath_slash = string_trimstart_ifmatch(p, "oil://")
                return string_replace(directory_abspath_slash, vim.fn.getcwd(), ".")
              elseif string_startswith(p, "/") then
                return string_replace(p, vim.fn.getcwd(), ".")
              else
                return "./" .. p
              end
            end,
          },
          lualine_x = {
            { "diff", source = function()
              local gsd = vim.b.gitsigns_status_dict -- cooporates with User GitSignsUpdate autocmd
              return {
                added = gsd and gsd.added or 0,
                modified = gsd and gsd.changed or 0,
                removed = gsd and gsd.removed or 0,
              }
            end },
            "diagnostics",
            { "lsp_status", separator = { left = " " } },
            { "filetype", cond = function() return not lsp_is_attached_for_current_buffer() end },
          },
          lualine_y = { "progress" },
          lualine_z = {},
        },
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufNewFile", "User NonOilBufReadPre" },
    config = function()
      ---@type LanguageConfig[]
      local languageconfigs = {
        {
          lspconfigname = "bashls",
        },
        {
          lspconfigname = "clangd",
          indentwidth = 4,
        },
        {
          lspconfigname = "gopls",
          tabtospace = false,
        },
        {
          lspconfigname = "hls",
        },
        {
          lspconfigname = "lean",
        },
        {
          lspconfigname = "lua_ls",
        },
        {
          lspconfigname = "nixd",
        },
        {
          lspconfigname = "rust_analyzer",
          indentwidth = 4,
        },
        {
          lspconfigname = "tinymist",
        },
        {
          lspconfigname = "vtsls",
          lspconfigsettings = {
            javascript = {
              suggest = {
                names = false,
              },
            },
          },
        },
        {
          filetypes = { "text", "markdown" },
          wrap = true,
        },
        {
          filetypes = { "kdl" },
          tabtospace = false,
        },
      }
      for _, lc in ipairs(languageconfigs) do
        applyLanguageConfig(lc)
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
        end,
      })
    end
  },
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufNewFile", "User NonOilBufReadPre" },
    config = function()
      require("nvim-treesitter").setup()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("vim-treesitter-start", { clear = true }),
        callback = function()
          pcall(vim.treesitter.start)
        end
      })
    end,
  },
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
  },
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-mini/mini.icons" },
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
    init = function()
      vim.cmd("colorscheme mellifluous")
      vim.opt.background = "light"
    end,
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
  dev = {
    path = "{{pluginsDir}}", -- replaced by nixos-configuration/home/neovim/default.nix
    patterns = { "." },
    fallback = false,
  },
})
