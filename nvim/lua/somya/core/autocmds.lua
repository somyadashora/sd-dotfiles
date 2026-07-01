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
    -- The extmark only shows once the screen redraws, but Neovim skips redraws
    -- while input is pending -- so on a slow machine, yanking in quick
    -- succession can let the 200ms clear-timer win before the flash ever paints.
    -- Force a redraw to paint it now, but only for interactive yanks: skip
    -- deletes/changes (no flash anyway) and macros (a forced redraw per
    -- iteration defeats redraw batching).
    if vim.v.event.operator == "y" and vim.fn.reg_executing() == "" then
      vim.cmd("redraw")
    end
  end,
})

-- Align comment/text auto-wrap with the first virt-column ruler, for ALL files.
--
-- We set `opt.textwidth` globally in core/options.lua, but many bundled
-- ftplugins clobber it per-buffer (verilog/systemverilog -> 78, gitcommit -> 72,
-- ...). A FileType autocmd runs after those ftplugins (they register during
-- startup, so we're later in registration order and win), so re-assert our
-- width on every buffer. `vim.g.sd_text_width` is the single knob (options.lua).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SDTextWidth", { clear = true }),
  pattern = "*",
  desc = "Force textwidth = g:sd_text_width on every filetype",
  callback = function()
    vim.bo.textwidth = vim.g.sd_text_width
  end,
})
