-- ============================================================
--  ~/.config/nvim/init.lua
--  Neovim config — ThinkPad T480 / Hyprland
--  Plugin manager: lazy.nvim
-- ============================================================

-- Load core settings first
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- Bootstrap and load lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
    change_detection = { notify = false },
    install          = { colorscheme = { "matugen", "habamax" } },
    ui               = { border = "rounded" },
    performance      = {
        rtp = {
            disabled_plugins = {
                "gzip", "matchit", "matchparen",
                "netrwPlugin", "tarPlugin", "tohtml",
                "tutor", "zipPlugin",
            },
        },
    },
})
