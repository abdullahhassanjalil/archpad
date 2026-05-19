-- ============================================================
--  ~/.config/nvim/lua/core/autocmds.lua
-- ============================================================

local au = vim.api.nvim_create_autocmd
local ag = vim.api.nvim_create_augroup

-- ── Highlight on yank ─────────────────────────────────────────
au("TextYankPost", {
    group    = ag("highlight_yank", { clear = true }),
    callback = function() vim.highlight.on_yank({ timeout = 200 }) end,
})

-- ── Restore cursor position ───────────────────────────────────
au("BufReadPost", {
    group    = ag("restore_cursor", { clear = true }),
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- ── Close some filetypes with q ───────────────────────────────
au("FileType", {
    group   = ag("close_with_q", { clear = true }),
    pattern = { "help", "lspinfo", "lazy", "mason", "notify",
                "qf", "checkhealth", "man", "spectre_panel" },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
    end,
})

-- ── Auto-reload matugen theme when colors file changes ────────
-- Watches matugen_colors.lua and reloads the colourscheme when it changes
au("FocusGained", {
    group    = ag("matugen_watch", { clear = true }),
    callback = function()
        local colors_file = vim.fn.expand("~/.config/nvim/lua/themes/matugen_colors.lua")
        if vim.fn.filereadable(colors_file) ~= 1 then return end
        local mtime = vim.fn.getftime(colors_file)
        if not vim.g.matugen_mtime then
            vim.g.matugen_mtime = mtime
            return
        end
        if mtime > vim.g.matugen_mtime then
            vim.g.matugen_mtime = mtime
            -- Clear cached require so new colours are loaded
            package.loaded["themes.matugen_colors"] = nil
            pcall(vim.cmd, "colorscheme matugen")
        end
    end,
})

-- ── 2-space indent for web files ──────────────────────────────
au("FileType", {
    group   = ag("two_space_indent", { clear = true }),
    pattern = { "javascript", "typescript", "html", "css", "json",
                "yaml", "lua", "vim", "scss" },
    callback = function()
        vim.opt_local.shiftwidth  = 2
        vim.opt_local.tabstop     = 2
        vim.opt_local.softtabstop = 2
    end,
})

-- ── Trim trailing whitespace on save ──────────────────────────
au("BufWritePre", {
    group    = ag("trim_whitespace", { clear = true }),
    callback = function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd([[%s/\s\+$//e]])
        vim.api.nvim_win_set_cursor(0, cursor)
    end,
})
