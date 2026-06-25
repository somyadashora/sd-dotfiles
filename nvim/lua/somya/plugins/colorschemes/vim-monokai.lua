return {
  -- ku1ik/vim-monokai is a classic Vimscript colorscheme — no setup(), just the
  -- colorscheme name `monokai` (distinct from the Lua monokai-pro-<filter> names).
  --
  -- lazy = true: loaded on demand. styler.nvim lists it as a dependency, so it
  -- loads on VeryLazy and is available for browsing (<leader>uc) without being a
  -- priority-1000 startup scheme. To use it as a per-filetype theme, add
  -- `{ colorscheme = "monokai" }` in core/theme.lua's M.styler_themes.
  "ku1ik/vim-monokai",
  name = "vim-monokai",
  lazy = true,
}
