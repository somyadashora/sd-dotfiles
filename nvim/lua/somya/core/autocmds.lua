-- Highlight yanked text for a brief moment.
--
-- `TextYankPost` + `vim.hl.on_yank` is the built-in, well-supported path. It
-- only flashes real yanks (it bails out unless `v:event.operator == "y"`), and
-- that is intentional: on a delete/change the text is gone from the buffer by
-- the time the event fires, so there is nothing left to highlight. Flashing a
-- delete *before* it happens would require intercepting the d/c/x operators,
-- which breaks dot-repeat, counts and custom text objects -- so we don't.
-- See https://github.com/neovim/neovim/issues/18271 (open feature request).
--
-- The flash colour comes from the live catppuccin palette (mocha by default),
-- re-applied on ColorScheme so it survives styler.nvim's reload cycle.

local group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })

local function set_hl()
  local ok, p = pcall(function() return require("catppuccin.palettes").get_palette() end)
  if not ok or not p then
    p = { green = "#a6e3a1", crust = "#11111b" }
  end
  vim.api.nvim_set_hl(0, "YankFlash", { fg = p.crust, bg = p.green, bold = true })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.hl.on_yank({ higroup = "YankFlash", timeout = 200 })
  end,
})
