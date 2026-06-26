-- sd-catppuccin-md ─ Catppuccin Mocha with a much darker background, for reading
-- and writing technical Markdown.
--
-- Mocha's NATIVE markdown highlighting already separates structure from code
-- nicely — rainbow headings (# red, ## peach, ### yellow, …) and green inline /
-- fenced code — and those pastels pop hard against a near-black background. So
-- this scheme keeps ALL of Mocha's colors untouched and only sinks the
-- background; it deliberately does NOT recolor headings or code.
--
-- Used by styler for the `markdown` filetype (core/theme.lua → M.styler_themes)
-- and selectable by name. It loads Catppuccin Mocha, then darkens the background
-- groups on top — no global Catppuccin setup change, so python (frappe) /
-- gitcommit (latte) are untouched. SignColumn / LineNr / EndOfBuffer carry no
-- background of their own, so they follow Normal automatically.

local ok, cat = pcall(require, "catppuccin")
if not ok then return end
local c = require("catppuccin.palettes").get_palette("mocha")

cat.load("mocha") -- base: every Mocha syntax / UI / markdown group, kept as-is

local bg     = "#0e0e16" -- editor background — well below Mocha's #1e1e2e
local bg_alt = "#0a0a11" -- floats / popups (Mocha keeps these below the editor)
local cline  = "#191926" -- cursorline lift above the new dark base

local function hl(group, opts) vim.api.nvim_set_hl(0, group, opts) end
for _, g in ipairs({ "Normal", "NormalNC" }) do hl(g, { fg = c.text, bg = bg }) end
hl("NormalFloat", { fg = c.text, bg = bg_alt })
hl("FloatBorder", { fg = c.surface2, bg = bg_alt })
hl("Pmenu",       { fg = c.subtext1, bg = bg_alt })
hl("StatusLine",  { fg = c.text, bg = bg_alt })
hl("CursorLine",  { bg = cline })
hl("ColorColumn", { bg = bg_alt })

-- Treesitter tags markdown code with the markdown-specific subgroups below, which
-- Catppuccin leaves UNDEFINED (it only defines the generic @markup.raw[.block]).
-- In a styler window an undefined group falls back to the GLOBAL scheme
-- (sd-monokai-catppuccin, which colors code yellow), so both inline `code` and
-- fenced blocks bleed yellow. Pin them to Mocha's own green @markup.raw[.block].
hl("@markup.raw.markdown_inline", { link = "@markup.raw" }) -- inline `code`
for _, g in ipairs({
  "@markup.raw.block.markdown",      -- fenced ``` blocks
  "@markup.raw.delimiter.markdown",  -- the ``` fences
  "@markup.raw.delimiter",
}) do
  hl(g, { link = "@markup.raw.block" })
end

vim.g.colors_name = "sd-catppuccin-md"
