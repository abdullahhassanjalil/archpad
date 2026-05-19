-- ============================================================
--  ~/.config/nvim/lua/core/keymaps.lua
-- ============================================================

local map = vim.keymap.set

-- ── General ──────────────────────────────────────────────────
map("n", "<Esc>",        "<cmd>nohlsearch<CR>",          { desc = "Clear search highlight" })
map("n", "<leader>q",    "<cmd>q<CR>",                   { desc = "Quit" })
map("n", "<leader>w",    "<cmd>w<CR>",                   { desc = "Save" })
map("n", "<leader>W",    "<cmd>wa<CR>",                  { desc = "Save all" })
map("n", "<leader>x",    "<cmd>x<CR>",                   { desc = "Save and quit" })

-- ── Better movement ───────────────────────────────────────────
map("n", "j",  "gj",   { desc = "Move down (wrapped)" })
map("n", "k",  "gk",   { desc = "Move up (wrapped)" })
map("n", "H",  "^",    { desc = "Go to line start" })
map("n", "L",  "$",    { desc = "Go to line end" })

-- ── Window navigation ─────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- ── Window resize ─────────────────────────────────────────────
map("n", "<C-Up>",    "<cmd>resize +2<CR>",          { desc = "Resize window up" })
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          { desc = "Resize window down" })
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", { desc = "Resize window left" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Resize window right" })

-- ── Buffer navigation ─────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ── Indenting in visual mode ──────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- ── Move lines ────────────────────────────────────────────────
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- ── Paste without overwriting register ───────────────────────
map("v", "p", '"_dP', { desc = "Paste without overwrite" })

-- ── Terminal ──────────────────────────────────────────────────
map("n", "<leader>t",  "<cmd>split | terminal<CR>", { desc = "Open terminal below" })
map("t", "<Esc><Esc>", "<C-\\><C-n>",               { desc = "Exit terminal mode" })

-- ── Diagnostics ───────────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev,  { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next,  { desc = "Next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })

-- ── Reload theme from matugen colours ────────────────────────
map("n", "<leader>tr", function()
    vim.cmd("colorscheme matugen")
    vim.notify("Theme reloaded", vim.log.levels.INFO)
end, { desc = "Reload matugen theme" })
