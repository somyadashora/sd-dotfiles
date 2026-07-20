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
    -- Auto theme OFF: its subtle brighten-of-Normal was too close to the
    -- editor to tell the peek apart. The Glance* groups in theme.lua's
    -- overrides_common paint the whole peek in the warm "dune" identity
    -- (dark sand-brown + Monokai amber accents — its own hue family, apart
    -- from the editor pastels, the teal panels, and the ember K hover) on
    -- every scheme, list-row matches included.
    theme = { enable = false },
    border = { enable = true }, -- top/bottom rule lines around the peek window
    -- RTL alignment padding makes lines long; a wrapped preview is
    -- disorienting (same reasoning as Trouble's lsp mode — see trouble.lua).
    preview_win_opts = { cursorline = true, number = true, wrap = false },
    folds = { folded = false }, -- start with all files' results visible
  },
  config = function(_, opts)
    local glance = require("glance")
    -- <C-g> ("g for glance") hops between the list and the preview text —
    -- single chord, symmetric from both sides. Free in normal mode config-wide
    -- (the <C-g> sticky-move chord in core/keymaps.lua is insert-mode only).
    opts.mappings = {
      list = { ["<C-g>"] = glance.actions.enter_win("preview") },
      preview = { ["<C-g>"] = glance.actions.enter_win("list") },
    }
    glance.setup(opts)
    -- Drop glance's default <leader>l window-hop: it shadows this config's
    -- <leader>l ("Lint & LazyGit") prefix inside peek windows, adding
    -- timeoutlen lag there. Glance reads mappings from config.options at
    -- window-open time, and its setup() deep-merge can't DELETE a default
    -- key (and false isn't a valid rhs), so nil it out after setup.
    local mappings = require("glance.config").options.mappings
    mappings.list["<leader>l"] = nil
    mappings.preview["<leader>l"] = nil
    -- Pin the preview window to the dune CONTENT scheme (theme.lua's
    -- surface_schemes.glance — monokai-pro-ristretto): the preview shows the
    -- real buffer, so without this its code keeps the editor's pastel
    -- highlighting (styler even re-pins it per filetype — pin_surface marks
    -- the window so styler skips it). Preview.create is the one place the
    -- window is made; the same window is reused as you <Tab> through results.
    local Preview = require("glance.preview")
    local preview_create = Preview.create
    Preview.create = function(popts)
      local preview = preview_create(popts)
      require("somya.core.theme").pin_surface(preview.winnr, "glance")
      return preview
    end
    -- Preview winbar: filename only. Glance hardcodes filename + ABSOLUTE
    -- dir (:p:~:h) with no option to trim, and deep RTL hierarchies push the
    -- name off-screen. Strip the filepath section in the render hook — the
    -- list window's winbar ("References (N)") passes no filepath, so it's
    -- untouched, and the list rows keep their cwd-relative dir for context.
    local Winbar = require("glance.winbar")
    local winbar_render = Winbar.render
    Winbar.render = function(self, sections)
      sections.filepath = nil
      return winbar_render(self, sections)
    end
  end,
}
