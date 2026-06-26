-- sd-catppuccin-md ─ a Catppuccin Mocha derivative tuned for reading and writing
-- technical Markdown. Two goals:
--   1. A much darker background than stock Mocha (#1e1e2e) so the pastels pop.
--   2. Headings and code live in deliberately DIFFERENT color families, so
--      "# Heading" and `inline code` / ``` fenced blocks ``` — both dense in
--      technical docs — never share an accent (Monokai/plain schemes do, which
--      is what this fixes).
--
-- Used by styler for the `markdown` filetype (core/theme.lua → M.styler_themes)
-- and selectable by name. It loads Catppuccin Mocha, then overrides the window
-- background + Markdown groups on top — it does NOT touch Catppuccin's global
-- setup, so python (frappe) / gitcommit (latte) are unaffected. (Catppuccin's
-- compiled output is captured by styler's namespace just like its other flavours.)

local ok, cat = pcall(require, "catppuccin")
if not ok then return end
local c = require("catppuccin.palettes").get_palette("mocha")

-- Base: Catppuccin Mocha (every syntax/UI group). Captured into styler's
-- per-filetype namespace when loaded as a theme; applied to ns 0 when selected.
cat.load("mocha")

local set = vim.api.nvim_set_hl
local function hl(group, opts) set(0, group, opts) end

-- ── Darker background ────────────────────────────────────────────────────────
local bg      = "#0e0e16" -- editor background, well below Mocha's #1e1e2e
local bg_dark = "#090910" -- sign column / floats / folds
local cline   = "#191926" -- cursorline lift
local code_bg = "#1c1b2a" -- inline-code chip / fenced-block panel

for _, g in ipairs({ "Normal", "NormalNC" }) do hl(g, { fg = c.text, bg = bg }) end
hl("NormalFloat",  { fg = c.text, bg = bg_dark })
hl("FloatBorder",  { fg = c.surface2, bg = bg_dark })
hl("SignColumn",   { bg = bg })
hl("EndOfBuffer",  { fg = bg, bg = bg })
hl("CursorLine",   { bg = cline })
hl("CursorLineNr", { fg = c.yellow, bold = true })
hl("LineNr",       { fg = c.surface2 })
hl("ColorColumn",  { bg = bg_dark })
hl("Folded",       { fg = c.blue, bg = bg_dark })
hl("WinSeparator", { fg = bg_dark })

-- ── Markdown: headings (cool gradient) vs code (warm peach chip) ─────────────
-- Headings: a per-level COOL gradient, bold — clearly not the code color.
local heading = { c.mauve, c.blue, c.sky, c.teal, c.lavender, c.sapphire }
for i, color in ipairs(heading) do
  hl("@markup.heading." .. i .. ".markdown", { fg = color, bold = true })
  hl("markdownH" .. i, { fg = color, bold = true })
end
hl("@markup.heading",          { fg = c.mauve, bold = true }) -- generic fallback
hl("@markup.heading.markdown", { bold = true })
hl("markdownHeadingDelimiter", { fg = c.overlay1, bold = true }) -- the leading #'s

-- Code: WARM peach on a subtle chip/panel — distinct hue AND a background, so it
-- reads as code at a glance and can't be confused with a heading.
for _, g in ipairs({ "@markup.raw", "@markup.raw.markdown_inline", "markdownCode" }) do
  hl(g, { fg = c.peach, bg = code_bg })
end
for _, g in ipairs({ "@markup.raw.block", "@markup.raw.block.markdown", "markdownCodeBlock" }) do
  hl(g, { bg = code_bg })
end
hl("@markup.raw.delimiter", { fg = c.overlay1 }) -- the ``` fences / backticks

-- Links, kept on their own hues so they don't collide with headings or code.
hl("@markup.link.label.markdown_inline", { fg = c.blue, underline = true })
hl("@markup.link.url",                   { fg = c.teal, underline = true })

vim.g.colors_name = "sd-catppuccin-md"
