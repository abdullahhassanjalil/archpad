-- ============================================================
--  ~/.config/nvim/colors/matugen.lua
--  Neovim colourscheme driven by matugen-generated colours
-- ============================================================

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
vim.g.colors_name  = "matugen"
vim.o.termguicolors = true
vim.o.background   = "dark"

-- Fallback warm retro palette (used until matugen generates colours)
local fallback = {
    primary            = "#c94a1a",
    on_primary         = "#e8dcc8",
    primary_container  = "#6b1010",
    secondary          = "#e07820",
    on_secondary       = "#2a1008",
    tertiary           = "#f5a623",
    on_tertiary        = "#2a1008",
    error              = "#a82010",
    on_error           = "#e8dcc8",
    background         = "#17130b",
    on_background      = "#ece1d4",
    surface            = "#211c13",
    on_surface         = "#ece1d4",
    surface_variant    = "#4e4639",
    on_surface_variant = "#d1c5b4",
    outline            = "#9a8f80",
    outline_variant    = "#4e4639",
    inverse_surface    = "#ece1d4",
    inverse_on_surface = "#17130b",
    inverse_primary    = "#c94a1a",
}

-- Load generated colours — validate they are real hex values not template strings
local ok, generated = pcall(require, "themes.matugen_colors")
local c = fallback
if ok and generated and type(generated.primary) == "string"
    and generated.primary:sub(1,1) == "#"
    and #generated.primary == 7 then
    -- Merge generated over fallback so any missing keys use fallback
    for k, v in pairs(generated) do
        if type(v) == "string" and v:sub(1,1) == "#" then
            c[k] = v
        end
    end
end

-- ── Helper ────────────────────────────────────────────────────

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Blend two hex colours at a given ratio (0.0 = full a, 1.0 = full b)
local function blend(hex_a, hex_b, ratio)
    local function parse(h) return tonumber(h:sub(2,3),16), tonumber(h:sub(4,5),16), tonumber(h:sub(6,7),16) end
    local r1,g1,b1 = parse(hex_a)
    local r2,g2,b2 = parse(hex_b)
    return string.format("#%02x%02x%02x",
        math.floor(r1 + (r2-r1)*ratio),
        math.floor(g1 + (g2-g1)*ratio),
        math.floor(b1 + (b2-b1)*ratio))
end

local dim    = blend(c.on_surface, c.background, 0.5)
local subtle = blend(c.on_surface, c.background, 0.7)
local muted  = blend(c.outline, c.background, 0.3)

-- ── Editor base ───────────────────────────────────────────────

hi("Normal",       { fg = c.on_background,      bg = c.background })
hi("NormalFloat",  { fg = c.on_surface,          bg = c.surface })
hi("NormalNC",     { fg = c.on_surface_variant,  bg = c.background })
hi("FloatBorder",  { fg = c.outline,             bg = c.surface })
hi("FloatTitle",   { fg = c.primary,             bg = c.surface, bold = true })

hi("Cursor",       { fg = c.background,    bg = c.primary })
hi("CursorLine",   { bg = c.surface })
hi("CursorColumn", { bg = c.surface })
hi("CursorLineNr", { fg = c.primary,       bold = true })
hi("LineNr",       { fg = c.outline })
hi("SignColumn",   { fg = c.outline,       bg = c.background })
hi("ColorColumn",  { bg = c.surface_variant })

hi("Visual",       { bg = blend(c.primary, c.background, 0.7) })
hi("VisualNOS",    { bg = blend(c.primary, c.background, 0.8) })
hi("Search",       { fg = c.on_primary,    bg = c.primary })
hi("IncSearch",    { fg = c.on_secondary,  bg = c.secondary })
hi("CurSearch",    { fg = c.on_primary,    bg = c.primary, bold = true })

hi("StatusLine",   { fg = c.on_surface,       bg = c.surface_variant })
hi("StatusLineNC", { fg = c.on_surface_variant, bg = c.surface })
hi("WinBar",       { fg = c.on_surface_variant, bg = c.background })
hi("WinBarNC",     { fg = c.outline,           bg = c.background })
hi("WinSeparator", { fg = c.outline_variant })

hi("TabLine",      { fg = c.on_surface_variant, bg = c.surface })
hi("TabLineFill",  { bg = c.surface })
hi("TabLineSel",   { fg = c.on_primary,         bg = c.primary, bold = true })

hi("Pmenu",        { fg = c.on_surface,     bg = c.surface })
hi("PmenuSel",     { fg = c.on_primary,     bg = c.primary })
hi("PmenuSbar",    { bg = c.surface_variant })
hi("PmenuThumb",   { bg = c.outline })

hi("Folded",       { fg = c.outline,        bg = c.surface })
hi("FoldColumn",   { fg = c.outline,        bg = c.background })

hi("MatchParen",   { fg = c.tertiary,       bold = true, underline = true })

hi("MsgArea",      { fg = c.on_surface })
hi("ModeMsg",      { fg = c.primary,        bold = true })
hi("MoreMsg",      { fg = c.secondary })
hi("WarningMsg",   { fg = c.tertiary,       bold = true })
hi("ErrorMsg",     { fg = c.error,          bold = true })

hi("NonText",      { fg = muted })
hi("Whitespace",   { fg = muted })
hi("SpecialKey",   { fg = muted })
hi("EndOfBuffer",  { fg = muted })

hi("Directory",    { fg = c.primary,        bold = true })
hi("Title",        { fg = c.primary,        bold = true })
hi("Question",     { fg = c.secondary })

-- ── Syntax ────────────────────────────────────────────────────

hi("Comment",      { fg = dim,              italic = true })
hi("Todo",         { fg = c.tertiary,       bg = blend(c.tertiary, c.background, 0.85), bold = true })
hi("Note",         { fg = c.secondary,      bold = true })
hi("Fixme",        { fg = c.error,          bold = true })

hi("Constant",     { fg = c.tertiary })
hi("String",       { fg = c.secondary })
hi("Character",    { fg = c.secondary })
hi("Number",       { fg = c.tertiary })
hi("Boolean",      { fg = c.primary,        bold = true })
hi("Float",        { fg = c.tertiary })

hi("Identifier",   { fg = c.on_surface })
hi("Function",     { fg = c.primary,        bold = true })
hi("Method",       { fg = c.primary })

hi("Statement",    { fg = c.primary })
hi("Conditional",  { fg = c.primary,        italic = true })
hi("Repeat",       { fg = c.primary,        italic = true })
hi("Label",        { fg = c.primary })
hi("Operator",     { fg = c.on_surface_variant })
hi("Keyword",      { fg = c.primary,        bold = true })
hi("Exception",    { fg = c.error })

hi("PreProc",      { fg = c.secondary })
hi("Include",      { fg = c.secondary })
hi("Define",       { fg = c.secondary })
hi("Macro",        { fg = c.secondary,      italic = true })

hi("Type",         { fg = c.tertiary,       bold = true })
hi("StorageClass", { fg = c.tertiary })
hi("Structure",    { fg = c.tertiary })
hi("Typedef",      { fg = c.tertiary })

hi("Special",      { fg = c.secondary })
hi("SpecialChar",  { fg = c.tertiary })
hi("Delimiter",    { fg = c.on_surface_variant })
hi("Tag",          { fg = c.primary })

hi("Underlined",   { underline = true })
hi("Error",        { fg = c.error })
hi("Ignore",       { fg = muted })

-- ── Treesitter ────────────────────────────────────────────────

hi("@comment",               { link = "Comment" })
hi("@string",                { link = "String" })
hi("@string.escape",         { fg = c.tertiary })
hi("@string.special",        { fg = c.tertiary })
hi("@number",                { link = "Number" })
hi("@float",                 { link = "Float" })
hi("@boolean",               { link = "Boolean" })
hi("@keyword",               { link = "Keyword" })
hi("@keyword.function",      { fg = c.primary, italic = true })
hi("@keyword.return",        { fg = c.primary, bold = true })
hi("@keyword.operator",      { fg = c.primary })
hi("@conditional",           { link = "Conditional" })
hi("@repeat",                { link = "Repeat" })
hi("@function",              { link = "Function" })
hi("@function.builtin",      { fg = c.secondary, bold = true })
hi("@function.call",         { fg = c.primary })
hi("@method",                { link = "Function" })
hi("@method.call",           { fg = c.primary })
hi("@constructor",           { fg = c.tertiary, bold = true })
hi("@parameter",             { fg = c.on_surface, italic = true })
hi("@variable",              { fg = c.on_surface })
hi("@variable.builtin",      { fg = c.secondary, italic = true })
hi("@type",                  { link = "Type" })
hi("@type.builtin",          { fg = c.tertiary, italic = true })
hi("@field",                 { fg = c.on_surface_variant })
hi("@property",              { fg = c.on_surface_variant })
hi("@namespace",             { fg = c.secondary })
hi("@operator",              { link = "Operator" })
hi("@punctuation.delimiter", { fg = c.on_surface_variant })
hi("@punctuation.bracket",   { fg = c.outline })
hi("@tag",                   { fg = c.primary })
hi("@tag.attribute",         { fg = c.secondary, italic = true })
hi("@tag.delimiter",         { fg = c.outline })
hi("@text.title",            { fg = c.primary, bold = true })
hi("@text.uri",              { fg = c.secondary, underline = true })
hi("@text.strong",           { bold = true })
hi("@text.emphasis",         { italic = true })
hi("@text.note",             { fg = c.secondary, bold = true })
hi("@text.warning",          { fg = c.tertiary, bold = true })
hi("@text.danger",           { fg = c.error, bold = true })

-- ── LSP ───────────────────────────────────────────────────────

hi("DiagnosticError",          { fg = c.error })
hi("DiagnosticWarn",           { fg = c.tertiary })
hi("DiagnosticInfo",           { fg = c.secondary })
hi("DiagnosticHint",           { fg = c.outline })
hi("DiagnosticUnderlineError", { undercurl = true, sp = c.error })
hi("DiagnosticUnderlineWarn",  { undercurl = true, sp = c.tertiary })
hi("DiagnosticUnderlineInfo",  { undercurl = true, sp = c.secondary })
hi("DiagnosticUnderlineHint",  { undercurl = true, sp = c.outline })
hi("DiagnosticVirtualTextError", { fg = c.error,    bg = blend(c.error, c.background, 0.9), italic = true })
hi("DiagnosticVirtualTextWarn",  { fg = c.tertiary, bg = blend(c.tertiary, c.background, 0.9), italic = true })
hi("DiagnosticVirtualTextInfo",  { fg = c.secondary, bg = blend(c.secondary, c.background, 0.9), italic = true })
hi("DiagnosticVirtualTextHint",  { fg = c.outline,  italic = true })

hi("LspReferenceText",  { bg = c.surface_variant })
hi("LspReferenceRead",  { bg = c.surface_variant })
hi("LspReferenceWrite", { bg = c.surface_variant, bold = true })

-- ── Git ───────────────────────────────────────────────────────

hi("DiffAdd",     { fg = c.tertiary, bg = blend(c.tertiary, c.background, 0.9) })
hi("DiffChange",  { fg = c.secondary, bg = blend(c.secondary, c.background, 0.9) })
hi("DiffDelete",  { fg = c.error,    bg = blend(c.error, c.background, 0.9) })
hi("DiffText",    { fg = c.primary,  bg = blend(c.primary, c.background, 0.85), bold = true })

hi("GitGutterAdd",    { fg = c.tertiary })
hi("GitGutterChange", { fg = c.secondary })
hi("GitGutterDelete", { fg = c.error })

-- ── Plugin-specific ───────────────────────────────────────────

-- nvim-tree / neo-tree
hi("NeoTreeNormal",        { fg = c.on_surface,     bg = c.surface })
hi("NeoTreeNormalNC",      { fg = c.on_surface,     bg = c.surface })
hi("NeoTreeRootName",      { fg = c.primary,        bold = true })
hi("NeoTreeDirectoryName", { fg = c.primary })
hi("NeoTreeDirectoryIcon", { fg = c.secondary })
hi("NeoTreeFileName",      { fg = c.on_surface })
hi("NeoTreeGitAdded",      { fg = c.tertiary })
hi("NeoTreeGitModified",   { fg = c.secondary })
hi("NeoTreeGitDeleted",    { fg = c.error })
hi("NeoTreeIndentMarker",  { fg = c.outline_variant })
hi("NeoTreeExpander",      { fg = c.outline })
hi("NeoTreeFloatBorder",   { fg = c.outline,        bg = c.surface })
hi("NeoTreeTitleBar",      { fg = c.on_primary,     bg = c.primary })

-- Telescope
hi("TelescopeNormal",         { fg = c.on_surface,     bg = c.surface })
hi("TelescopeBorder",         { fg = c.outline,        bg = c.surface })
hi("TelescopePromptNormal",   { fg = c.on_surface,     bg = c.surface_variant })
hi("TelescopePromptBorder",   { fg = c.primary,        bg = c.surface_variant })
hi("TelescopePromptTitle",    { fg = c.on_primary,     bg = c.primary, bold = true })
hi("TelescopePreviewTitle",   { fg = c.on_secondary,   bg = c.secondary, bold = true })
hi("TelescopeResultsTitle",   { fg = c.on_surface,     bg = c.surface })
hi("TelescopeSelectionCaret", { fg = c.primary })
hi("TelescopeSelection",      { fg = c.on_surface,     bg = blend(c.primary, c.surface, 0.85) })
hi("TelescopeMatching",       { fg = c.primary,        bold = true })

-- Which-key
hi("WhichKey",          { fg = c.primary })
hi("WhichKeyGroup",     { fg = c.secondary, bold = true })
hi("WhichKeyDesc",      { fg = c.on_surface })
hi("WhichKeySeparator", { fg = c.outline })
hi("WhichKeyFloat",     { bg = c.surface })
hi("WhichKeyBorder",    { fg = c.outline, bg = c.surface })

-- Notify
hi("NotifyERRORBorder", { fg = c.error })
hi("NotifyWARNBorder",  { fg = c.tertiary })
hi("NotifyINFOBorder",  { fg = c.secondary })
hi("NotifyDEBUGBorder", { fg = c.outline })
hi("NotifyERRORTitle",  { fg = c.error,     bold = true })
hi("NotifyWARNTitle",   { fg = c.tertiary,  bold = true })
hi("NotifyINFOTitle",   { fg = c.secondary, bold = true })
hi("NotifyERRORBody",   { fg = c.on_surface })
hi("NotifyWARNBody",    { fg = c.on_surface })
hi("NotifyINFOBody",    { fg = c.on_surface })

-- nvim-cmp
hi("CmpItemAbbr",           { fg = c.on_surface })
hi("CmpItemAbbrMatch",      { fg = c.primary,    bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = c.primary })
hi("CmpItemMenu",           { fg = c.outline,    italic = true })
hi("CmpItemKindFunction",   { fg = c.primary })
hi("CmpItemKindMethod",     { fg = c.primary })
hi("CmpItemKindVariable",   { fg = c.on_surface })
hi("CmpItemKindKeyword",    { fg = c.primary })
hi("CmpItemKindText",       { fg = c.secondary })
hi("CmpItemKindSnippet",    { fg = c.tertiary })

-- indent-blankline
hi("IblIndent",   { fg = blend(c.outline_variant, c.background, 0.6) })
hi("IblScope",    { fg = blend(c.primary, c.background, 0.7) })
