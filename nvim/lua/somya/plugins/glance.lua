-- VSCode-style "peek": gp* opens an embedded preview window INSIDE the current
-- window — definition/references/implementations/type-def with a navigable
-- list on the side — so you inspect (even edit) the target without jumping
-- away or losing your place. Division of labor with the rest of the config:
--   K            hover float  — info ABOUT the symbol (custom slang-aware K)
--   gd/gR/gi/gt  Telescope    — fuzzy-pick, then JUMP to the location
--   <leader>xr   Trouble      — persistent defs/refs sidebar
--   gl*          glance       — look at the source in place, then come back
-- Works with any LSP client (verible/slang/lua_ls). Preview panes are real
-- file buffers, so highlighting degrades gracefully on no-treesitter hosts
-- (regex syntax applies there like in any window). Fully lazy: loads on
-- first gl* keypress or :Glance. The gl prefix ("gl-ance") is free in stock
-- nvim AND this config — gp/gP were rejected because yanky owns both as
-- ring-aware puts, and stacking gpd on gp would add timeout lag to pastes.
return {
  "dnlhc/glance.nvim",
  cmd = "Glance",
  keys = {
    { "gld", "<cmd>Glance definitions<cr>", desc = "Peek definitions (glance)" },
    { "glr", "<cmd>Glance references<cr>", desc = "Peek references (glance)" },
    { "gli", "<cmd>Glance implementations<cr>", desc = "Peek implementations (glance)" },
    { "glt", "<cmd>Glance type_definitions<cr>", desc = "Peek type definitions (glance)" },
  },
  opts = {
    -- Auto theme: list/preview backgrounds are lightened shades of the active
    -- scheme's Normal, and the border lines take FloatBorder's fg — i.e. the
    -- teal from theme.lua's overrides_common — re-derived on every
    -- ColorScheme, so the peek window matches the hover float's identity on
    -- any scheme without extra highlight plumbing here.
    theme = { enable = true, mode = "auto" },
    border = { enable = true }, -- top/bottom rule lines around the peek window
    -- RTL alignment padding makes lines long; a wrapped preview is
    -- disorienting (same reasoning as Trouble's lsp mode — see trouble.lua).
    preview_win_opts = { cursorline = true, number = true, wrap = false },
    folds = { folded = false }, -- start with all files' results visible
  },
}
