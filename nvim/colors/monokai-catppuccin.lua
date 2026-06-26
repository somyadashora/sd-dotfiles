-- monokai-catppuccin ─ Monokai Pro's highlight *structure* with the Catppuccin
-- (Mocha) pastel palette dropped into Monokai's 15 palette slots, on a much
-- darker background than stock Catppuccin so the pastels really pop.
--
-- It's not a separate plugin: it drives monokai-pro.nvim through its public
-- `override_palette` hook, so every Monokai highlight group (editor, syntax,
-- treesitter, LSP, plugins) is reused verbatim — only the colors change.
--
-- This lives in colors/ (not plugins/colorschemes/) because it's a colorscheme
-- *file*, not a lazy plugin spec — `:colorscheme monokai-catppuccin`, Telescope's
-- picker, and <leader>uc all discover it from the runtimepath.
--
-- override_palette is a GLOBAL monokai-pro setting, so we snapshot the live config,
-- apply our palette, then restore it — otherwise styler's monokai-pro-spectrum on
-- .sv buffers would turn Catppuccin too. (To give this scheme its own line-number
-- / cursor tweaks, add a { pat = "^monokai%-catppuccin", hl = {...} } entry to
-- core/theme.lua → M.overrides.)

local ok, mp = pcall(require, "monokai-pro")
if not ok then
  -- Selected before monokai-pro loaded (rare) — pull it in, then retry.
  pcall(function() require("lazy").load({ plugins = { "monokai-pro.nvim" } }) end)
  ok, mp = pcall(require, "monokai-pro")
  if not ok then return end
end

local config = require("monokai-pro.config")
local theme = require("monokai-pro.theme")

-- Catppuccin Mocha → Monokai palette slots. The background trio is pushed well
-- below Catppuccin's base (#1e1e2e) so the pastel accents read as vivid.
local palette = {
  dark2      = "#08080c", -- darkest: shadows / deep UI
  dark1      = "#0d0d15", -- sidebar / float background
  background = "#13131d", -- editor background — intentionally very dark
  text       = "#cdd6f4", -- Catppuccin text
  accent1    = "#f38ba8", -- red
  accent2    = "#fab387", -- peach   (Monokai orange slot)
  accent3    = "#f9e2af", -- yellow
  accent4    = "#a6e3a1", -- green
  accent5    = "#89dceb", -- sky     (Monokai cyan/blue slot)
  accent6    = "#cba6f7", -- mauve   (Monokai purple slot)
  dimmed1    = "#bac2de", -- subtext1 (active text)
  dimmed2    = "#9399b2", -- overlay2 (borders)
  dimmed3    = "#7f849c", -- overlay1 (comments)
  dimmed4    = "#585b70", -- surface2
  dimmed5    = "#313244", -- surface0 (cursorline / UI lift — sits above the bg)
}

-- monokai-pro forces the "light" filter when background is light; keep it dark.
vim.o.background = "dark"

-- Snapshot the live monokai-pro config so we can put it back afterwards.
local saved = vim.deepcopy(config.get())

-- Apply our palette through monokai-pro's machinery. setup() rebuilds from
-- defaults, so we pass the saved config (filter/styles/plugins) plus our hook.
config.setup(vim.tbl_deep_extend("force", vim.deepcopy(saved), {
  override_palette = function() return palette end,
}))
theme.clear_cache()

-- monokai-pro's load() does `hi clear`, hardcodes colors_name = "monokai-pro",
-- and fires ColorScheme as that name. Suppress that fire (otherwise our
-- per-scheme overrides in core/theme.lua would apply monokai-pro's values on top
-- of ours), then set the real name and fire ColorScheme ourselves so everything
-- — our overrides, lualine's auto theme, … — reacts to "monokai-catppuccin".
local ei = vim.o.eventignore
vim.o.eventignore = "ColorScheme"
mp.load() -- applies the catppuccin highlights to the global namespace
vim.o.eventignore = ei

vim.g.colors_name = "monokai-catppuccin"
vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "monokai-catppuccin" })

-- Restore the original config (drops override_palette) so later monokai-pro /
-- monokai-pro-spectrum loads (e.g. styler on .sv) are completely unaffected.
config.setup(saved)
theme.clear_cache()
