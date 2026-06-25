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

    vim.keymap.set("n", "<leader>uy", theme.toggle_styler,
      { desc = "Toggle styler per-filetype themes" })
    vim.keymap.set("n", "<leader>uc", theme.browse,
      { desc = "Browse colorschemes (full-window preview)" })
  end,
}
