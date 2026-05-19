-- ============================================================
--  ~/.config/nvim/lua/plugins/init.lua
--  All plugins loaded via lazy.nvim
-- ============================================================

return {

    -- ── Colourscheme (matugen — our custom generated theme) ────
    {
        name = "matugen",
        dir  = vim.fn.stdpath("config"),
        priority = 1000,
        lazy = false,
        config = function()
            vim.cmd("colorscheme matugen")
        end,
    },

    -- ── Treesitter — nvim-treesitter archived April 2026
    -- Neovim 0.12 has native treesitter built in.
    -- Parsers are installed via :TSInstall or vim.treesitter.language.add()
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        branch = "main",           -- use new main branch
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            -- Install parsers using the new API
            require("nvim-treesitter").install({
                "bash", "c", "css", "html", "javascript",
                "json", "lua", "markdown", "markdown_inline",
                "python", "rust", "toml", "typescript",
                "yaml", "vim", "vimdoc",
            })
            -- Enable highlighting via native Neovim treesitter
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
            -- Enable indentation
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    local ok = pcall(function()
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end)
                    if not ok then
                        vim.bo.indentexpr = ""
                    end
                end,
            })
        end,
    },

    -- ── LSP ────────────────────────────────────────────────────
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("mason").setup({ ui = { border = "rounded" } })
            require("mason-lspconfig").setup({
                -- Use correct Mason package names
                ensure_installed = { "lua_ls", "basedpyright" },
            })

            -- New nvim-lspconfig v3 API — use vim.lsp.config instead of lspconfig[x].setup
            local capabilities = vim.tbl_deep_extend("force",
                vim.lsp.protocol.make_client_capabilities(),
                require("cmp_nvim_lsp").default_capabilities()
            )

            local on_attach = function(_, bufnr)
                local map = function(keys, func, desc)
                    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
                end
                map("gd",         vim.lsp.buf.definition,      "Go to definition")
                map("gD",         vim.lsp.buf.declaration,     "Go to declaration")
                map("gr",         vim.lsp.buf.references,      "References")
                map("gi",         vim.lsp.buf.implementation,  "Go to implementation")
                map("K",          vim.lsp.buf.hover,           "Hover docs")
                map("<leader>rn", vim.lsp.buf.rename,          "Rename symbol")
                map("<leader>ca", vim.lsp.buf.code_action,     "Code action")
                map("<leader>f",  function() vim.lsp.buf.format({ async = true }) end, "Format")
            end

            -- Configure servers using new API
            local servers = { "lua_ls", "basedpyright", "bashls" }
            for _, server in ipairs(servers) do
                vim.lsp.config(server, {
                    capabilities = capabilities,
                    on_attach    = on_attach,
                })
                vim.lsp.enable(server)
            end

            -- Diagnostic config
            vim.diagnostic.config({
                virtual_text  = { prefix = "●" },
                signs         = true,
                underline     = true,
                severity_sort = true,
                float         = { border = "rounded" },
            })
        end,
    },

    -- ── Completion ─────────────────────────────────────────────
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
        },
        event = "InsertEnter",
        config = function()
            local cmp    = require("cmp")
            local luasnip = require("luasnip")
            require("luasnip.loaders.from_vscode").lazy_load()

            cmp.setup({
                snippet = {
                    expand = function(args) luasnip.lsp_expand(args.body) end,
                },
                window = {
                    completion    = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-n>"]     = cmp.mapping.select_next_item(),
                    ["<C-p>"]     = cmp.mapping.select_prev_item(),
                    ["<C-d>"]     = cmp.mapping.scroll_docs(4),
                    ["<C-u>"]     = cmp.mapping.scroll_docs(-4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"]     = cmp.mapping.abort(),
                    ["<CR>"]      = cmp.mapping.confirm({ select = false }),
                    ["<Tab>"]     = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                        else fallback() end
                    end, { "i", "s" }),
                    ["<S-Tab>"]   = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then luasnip.jump(-1)
                        else fallback() end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer",  keyword_length = 3 },
                    { name = "path" },
                }),
                formatting = {
                    format = function(entry, item)
                        local icons = {
                            Text = "󰉿", Method = "󰆧", Function = "󰊕",
                            Constructor = "", Field = "󰜢", Variable = "󰀫",
                            Class = "󰠱", Interface = "", Module = "",
                            Property = "󰜢", Unit = "󰑭", Value = "󰎠",
                            Enum = "", Keyword = "󰌋", Snippet = "",
                            Color = "󰏘", File = "󰈙", Reference = "󰈇",
                            Folder = "󰉋", EnumMember = "", Constant = "󰏿",
                            Struct = "󰙅", Event = "", Operator = "󰆕",
                            TypeParameter = "",
                        }
                        item.kind = string.format("%s %s", icons[item.kind] or "", item.kind)
                        item.menu = ({
                            nvim_lsp = "[LSP]",
                            luasnip  = "[Snip]",
                            buffer   = "[Buf]",
                            path     = "[Path]",
                        })[entry.source.name]
                        return item
                    end,
                },
            })
        end,
    },

    -- ── Telescope ──────────────────────────────────────────────
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        },
        cmd = "Telescope",
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<CR>",   desc = "Find files" },
            { "<leader>fg", "<cmd>Telescope live_grep<CR>",    desc = "Live grep" },
            { "<leader>fb", "<cmd>Telescope buffers<CR>",      desc = "Buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<CR>",    desc = "Help" },
            { "<leader>fr", "<cmd>Telescope oldfiles<CR>",     desc = "Recent files" },
            { "<leader>fc", "<cmd>Telescope colorscheme<CR>",  desc = "Colorschemes" },
        },
        config = function()
            require("telescope").setup({
                defaults = {
                    prompt_prefix  = "  ",
                    selection_caret = " ",
                    border         = true,
                    layout_config  = { prompt_position = "top" },
                    sorting_strategy = "ascending",
                    file_ignore_patterns = { "node_modules", ".git/" },
                },
            })
            require("telescope").load_extension("fzf")
        end,
    },

    -- ── Neo-tree (file explorer) ───────────────────────────────
    {
        "nvim-neo-tree/neo-tree.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        keys = {
            { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
            { "<leader>o", "<cmd>Neotree focus<CR>",  desc = "Focus file tree" },
        },
        config = function()
            require("neo-tree").setup({
                close_if_last_window = true,
                window = { width = 30, position = "left" },
                filesystem = {
                    filtered_items = {
                        visible        = false,
                        hide_dotfiles  = false,
                        hide_gitignored = true,
                    },
                    follow_current_file = { enabled = true },
                },
            })
        end,
    },

    -- ── Lualine (statusline) ───────────────────────────────────
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        event = "VeryLazy",
        config = function()
            -- Read matugen colours for lualine
            local ok, c = pcall(require, "themes.matugen_colors")
            if not ok then
                c = { primary = "#c94a1a", secondary = "#e07820",
                      tertiary = "#f5a623", background = "#17130b",
                      surface = "#211c13", surface_variant = "#4e4639",
                      on_primary = "#e8dcc8", on_surface = "#ece1d4",
                      on_surface_variant = "#d1c5b4", outline = "#9a8f80",
                      error = "#a82010", on_error = "#e8dcc8" }
            end

            local theme = {
                normal = {
                    a = { fg = c.on_primary,         bg = c.primary,         gui = "bold" },
                    b = { fg = c.on_surface,          bg = c.surface_variant },
                    c = { fg = c.on_surface_variant,  bg = c.surface },
                },
                insert   = { a = { fg = c.on_primary, bg = c.secondary, gui = "bold" } },
                visual   = { a = { fg = c.on_primary, bg = c.tertiary,  gui = "bold" } },
                replace  = { a = { fg = c.on_error,   bg = c.error,     gui = "bold" } },
                command  = { a = { fg = c.on_primary, bg = c.outline,   gui = "bold" } },
                inactive = {
                    a = { fg = c.outline, bg = c.surface },
                    b = { fg = c.outline, bg = c.surface },
                    c = { fg = c.outline, bg = c.surface },
                },
            }

            require("lualine").setup({
                options = {
                    theme            = theme,
                    component_separators = { left = "", right = "" },
                    section_separators  = { left = "", right = "" },
                    globalstatus     = true,
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 } },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },

    -- ── Which-key ─────────────────────────────────────────────
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local wk = require("which-key")
            wk.setup({
                win = { border = "rounded" },
            })
            wk.add({
                { "<leader>f", group = "Find" },
                { "<leader>b", group = "Buffer" },
                { "<leader>l", group = "LSP" },
                { "<leader>g", group = "Git" },
            })
        end,
    },

    -- ── Gitsigns ───────────────────────────────────────────────
    {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("gitsigns").setup({
                signs = {
                    add          = { text = "▎" },
                    change       = { text = "▎" },
                    delete       = { text = "" },
                    topdelete    = { text = "" },
                    changedelete = { text = "▎" },
                },
                on_attach = function(bufnr)
                    local gs = package.loaded.gitsigns
                    local map = function(mode, l, r, desc)
                        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
                    end
                    map("n", "]h", gs.next_hunk,              "Next hunk")
                    map("n", "[h", gs.prev_hunk,              "Prev hunk")
                    map("n", "<leader>gp", gs.preview_hunk,   "Preview hunk")
                    map("n", "<leader>gb", gs.blame_line,     "Blame line")
                    map("n", "<leader>gr", gs.reset_hunk,     "Reset hunk")
                    map("n", "<leader>gR", gs.reset_buffer,   "Reset buffer")
                    map("n", "<leader>gs", gs.stage_hunk,     "Stage hunk")
                end,
            })
        end,
    },

    -- ── Indent guides ──────────────────────────────────────────
    {
        "lukas-reineke/indent-blankline.nvim",
        main  = "ibl",
        event = { "BufReadPost", "BufNewFile" },
        config = function()
            require("ibl").setup({
                indent   = { char = "│" },
                scope    = { enabled = true },
                exclude  = { filetypes = { "help", "lazy", "mason", "neo-tree" } },
            })
        end,
    },

    -- ── Autopairs ──────────────────────────────────────────────
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({ check_ts = true })
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
    },

    -- ── Comment ────────────────────────────────────────────────
    {
        "numToStr/Comment.nvim",
        keys = {
            { "gcc", mode = "n", desc = "Comment line" },
            { "gc",  mode = "v", desc = "Comment selection" },
        },
        config = true,
    },

    -- ── Surround ───────────────────────────────────────────────
    {
        "kylechui/nvim-surround",
        event   = "VeryLazy",
        version = "*",
        config  = true,
    },

    -- ── Better notifications ───────────────────────────────────
    {
        "rcarriga/nvim-notify",
        lazy   = false,
        config = function()
            local ok, c = pcall(require, "themes.matugen_colors")
            local bg = "#211c13"
            if ok and c and type(c.surface) == "string"
               and c.surface:sub(1,1) == "#" and #c.surface == 7 then
                bg = c.surface
            end
            require("notify").setup({
                background_colour = bg,
                border            = "rounded",
                stages            = "fade",
                timeout           = 3000,
                max_width         = 50,
            })
            vim.notify = require("notify")
        end,
    },

    -- ── Todo comments ──────────────────────────────────────────
    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        event        = { "BufReadPost", "BufNewFile" },
        config       = true,
    },

    -- ── Web devicons ───────────────────────────────────────────
    { "nvim-tree/nvim-web-devicons", lazy = true },

    -- ── Plenary (utility) ──────────────────────────────────────
    { "nvim-lua/plenary.nvim", lazy = true },
}
