return {
  -- material.nvim exposes ONE colorscheme name (`material`); the variant is
  -- chosen via `vim.g.material_style` (darker | lighter | oceanic | palenight |
  -- deep ocean), unlike tokyonight/catppuccin whose variants are distinct names.
  -- So only `material` shows in :Telescope colorscheme — switch style here.
  --
  -- lazy = true: loaded on demand. styler.nvim lists it as a dependency, so it
  -- loads on VeryLazy and is available for browsing (<leader>uc) without being a
  -- priority-1000 startup scheme. To use it as a per-filetype theme, add
  -- `{ colorscheme = "material" }` in core/theme.lua's M.styler_themes.
  "marko-cerovac/material.nvim",
  lazy = true,
  config = function()
    vim.g.material_style = "deep ocean" -- dark, navy-leaning — fits the editor
    require("material").setup({})
  end,
}
