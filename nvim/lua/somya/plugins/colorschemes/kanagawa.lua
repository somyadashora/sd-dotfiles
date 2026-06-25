return {
  -- kanagawa.nvim exposes three variant *names* — kanagawa-wave (dark, default),
  -- kanagawa-dragon (darker), kanagawa-lotus (light) — so all three show up in
  -- :Telescope colorscheme, like tokyonight/catppuccin (not material's single name).
  --
  -- lazy = true: loaded on demand. styler.nvim lists it as a dependency, so it
  -- loads on VeryLazy and is available for browsing (<leader>uc) without being a
  -- priority-1000 startup scheme. To use it as a per-filetype theme, add
  -- `{ colorscheme = "kanagawa-wave" }` in core/theme.lua's M.styler_themes.
  "rebelot/kanagawa.nvim",
  lazy = true,
  config = function()
    require("kanagawa").setup({})
  end,
}
