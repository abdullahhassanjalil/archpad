-- ============================================================
--  ~/.config/nvim/lua/core/options.lua
-- ============================================================

local opt = vim.opt

-- ── UI ────────────────────────────────────────────────────────
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.termguicolors  = true
opt.showmode       = false
opt.laststatus     = 3        -- global statusline
opt.cmdheight      = 1
opt.scrolloff      = 8
opt.sidescrolloff  = 8
opt.wrap           = false
opt.linebreak      = true
opt.breakindent    = true
opt.colorcolumn    = "100"
opt.fillchars      = { eob = " ", fold = " ", vert = "│" }
opt.list           = true
opt.listchars      = { tab = "→ ", trail = "·", nbsp = "␣" }

-- ── Editing ───────────────────────────────────────────────────
opt.expandtab      = true
opt.shiftwidth     = 4
opt.tabstop        = 4
opt.softtabstop    = 4
opt.smartindent    = true
opt.autoindent     = true

-- ── Search ───────────────────────────────────────────────────
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true
opt.incsearch      = true

-- ── Files ────────────────────────────────────────────────────
opt.undofile       = true
opt.swapfile       = false
opt.backup         = false
opt.updatetime     = 200
opt.timeoutlen     = 400

-- ── Windows ──────────────────────────────────────────────────
opt.splitright     = true
opt.splitbelow     = true

-- ── Completion ───────────────────────────────────────────────
opt.completeopt    = { "menu", "menuone", "noselect" }
opt.pumheight      = 10

-- ── Misc ─────────────────────────────────────────────────────
opt.mouse          = "a"
opt.clipboard      = "unnamedplus"
opt.conceallevel   = 2
opt.confirm        = true

-- Leader key
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"
