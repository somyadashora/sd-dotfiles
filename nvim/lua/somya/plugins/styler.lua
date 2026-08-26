return {
  "folke/styler.nvim",
  event = "VeryLazy",
  -- Pull in the colorschemes styler switches to, so they load with styler rather
  -- than eagerly at startup. (catppuccin/tokyonight already load via priority.)
  dependencies = {
    "loctvl842/monokai-pro.nvim",
    "marko-cerovac/material.nvim",
    "rebelot/kanagawa.nvim",
    "scottmckendry/cyberdream.nvim",
    "ku1ik/vim-monokai",
  },
  config = function()
    -- The per-filetype theme table + enable/disable/browse logic all live in
    -- core/theme.lua so the colorscheme default and styler share one home.
    -- Per-filetype themes are ON by default: enable_styler() below registers
    -- styler's autocmds and pins every open window as soon as this plugin loads
    -- (VeryLazy). <leader>uy / :StylerToggle turns them off/on from there.
    local theme = require("somya.core.theme")
    theme.enable_styler()

    -- ── Theme-management commands + keymaps (<leader>u = +UI/Theme) ──────────
    -- styler pins a per-filetype colorscheme window-locally, so `:colorscheme X`
    -- (e.g. Telescope's picker) only affects unmapped windows. Toggle styler off
    -- to preview a scheme across every window, pick one, then toggle back on.
    vim.api.nvim_create_user_command("StylerToggle", theme.toggle_styler, {
      desc = "Toggle styler.nvim per-filetype themes on/off",
    })
    vim.api.nvim_create_user_command("ThemeBrowse", theme.browse, {
      desc = "Browse colorschemes (styler off + live full-window preview)",
    })

    -- Italics on/off across every scheme + styler namespace. Terminals whose
    -- font has no real italic face fake the slant and clip it at the cell edge
    -- (see the Italics section in core/theme.lua); theme.italics defaults to
    -- "auto", which asks terminfo, but terminfo can't see the FONT — so this is
    -- the key you reach for when the auto answer is wrong.
    vim.api.nvim_create_user_command("ItalicsToggle", theme.toggle_italics, {
      desc = "Toggle italic highlights on/off (terminal italic rendering)",
    })

    vim.keymap.set("n", "<leader>uy", theme.toggle_styler,
      { desc = "Toggle styler per-filetype themes" })
    vim.keymap.set("n", "<leader>uc", theme.browse,
      { desc = "Browse colorschemes (full-window preview)" })
    vim.keymap.set("n", "<leader>ui", theme.toggle_italics,
      { desc = "Toggle italics (terminal rendering)" })
  end,
}
