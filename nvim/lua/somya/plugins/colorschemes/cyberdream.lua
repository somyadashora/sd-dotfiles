return {
  -- cyberdream.nvim exposes ONE colorscheme name (`cyberdream`); the light/dark
  -- variant is chosen via the `variant` opt below (or follows background), so only
  -- `cyberdream` shows in :Telescope colorscheme (like material, unlike the
  -- multi-name tokyonight/catppuccin/kanagawa).
  --
  -- lazy = true: loaded on demand. styler.nvim lists it as a dependency, so it
  -- loads on VeryLazy and is available for browsing (<leader>uc) without being a
  -- priority-1000 startup scheme. To use it as a per-filetype theme, add
  -- `{ colorscheme = "cyberdream" }` in core/theme.lua's M.styler_themes.
  "scottmckendry/cyberdream.nvim",
  lazy = true,
  config = function()
    require("cyberdream").setup({
      variant = "default", -- default (dark) | light | auto (follows background)
    })
  end,
}
