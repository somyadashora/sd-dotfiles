-- Central theme/colorscheme management.
--
-- The colorscheme *plugins* live in plugins/colorschemes/ — tokyonight and
-- catppuccin (loaded eagerly), plus monokai-pro, material, kanagawa, cyberdream,
-- and vim-monokai (loaded via styler). Most expose many *variants*:
-- tokyonight-night/storm/moon, catppuccin-latte/frappe/macchiato/mocha,
-- monokai-pro-<filter>, kanagawa-wave/dragon/lotus — those names are what you see
-- in `:Telescope colorscheme`, not separate files. (material and cyberdream are
-- exceptions: one name each — `material` / `cyberdream` — with the variant set via
-- `vim.g.material_style` / cyberdream's `variant` opt. vim-monokai is the classic
-- Vimscript scheme, single name `monokai`.)
--
-- Two layers cooperate:
--   1. A single global default colorscheme (M.default), loaded at startup.
--   2. styler.nvim, which *overrides* the global scheme per filetype, window-
--      locally (see M.styler_themes). When on, this is why `:colorscheme X`
--      changes the file explorer but NOT a .sv/.py buffer — that window is
--      pinned by styler.
--
-- styler starts ON: plugins/styler.lua calls enable_styler() when the plugin
-- loads (VeryLazy), so per-filetype themes apply by default. Toggle them off
-- with <leader>uy / :StylerToggle. Browsing schemes with a full-window preview
-- (<leader>uc) suspends styler first — re-enable with <leader>uy after picking.
-- Lock a winner in by editing M.default.

local M = {}

-- ── Single source of truth: the startup colorscheme ────────────────────────
-- Edit this one line to change the default applied on `nvim` launch.
-- NOTE: the default must be loadable at startup. tokyonight.lua runs the
-- `colorscheme` command (priority 1000) and lists this scheme's plugin as a
-- dependency so it's loaded + set up first. If you point this at a different
-- lazy scheme, add it to tokyonight.lua's `dependencies` too.
M.default = "sd-monokai-catppuccin"

-- ── styler.nvim: per-filetype window-local colorschemes ─────────────────────
M.styler_themes = {
  -- Hardware description languages
  systemverilog = { colorscheme = "sd-monokai-catppuccin" },
  verilog       = { colorscheme = "sd-monokai-catppuccin" },
  vhdl          = { colorscheme = "sd-monokai-catppuccin" },

  -- Scripting / general purpose
  python        = { colorscheme = "tokyonight-storm" },
  sh            = { colorscheme = "tokyonight-storm" },
  bash          = { colorscheme = "tokyonight-storm" },
  tcl           = { colorscheme = "tokyonight-storm" },

  -- Build / config
  make          = { colorscheme = "tokyonight-storm" },

  -- Markdown — custom dark-Catppuccin scheme (colors/sd-catppuccin-md.lua) that
  -- keeps headings and code in distinct color families for technical docs.
  markdown      = { colorscheme = "sd-catppuccin-md" },

  -- Git
  gitcommit     = { colorscheme = "tokyonight-storm" },
  gitconfig     = { colorscheme = "tokyonight-storm" },
  gitrebase     = { colorscheme = "tokyonight-storm" },
}

-- ── Per-colorscheme highlight overrides ─────────────────────────────────────
-- Tweaks we want on top of whatever colorscheme is active: cursor, line-number,
-- and cursorline colors that differ PER scheme, plus a set of common tweaks
-- (search, marks) that stay consistent everywhere.
--
-- This used to live (hardcoded, one global set) inside colorschemes/tokyonight.lua,
-- which made that file the de-facto "theme main file". It now lives here, the
-- single source of truth, and is keyed by the colorscheme name — so a .sv buffer
-- (monokai-pro-spectrum) and a .py buffer (catppuccin-frappe) each get the colors
-- defined for THEIR scheme. To give a new colorscheme its own line-number /
-- cursorline / cursor colors, just add an entry to M.overrides below.
--
-- Applied both to the global scheme (ns 0) and into every styler per-filetype
-- namespace (see M.wire_overrides). A scheme with no matching entry keeps its
-- own native cursor/gutter colors — only the common set is forced.

-- Forced on every scheme (the deliberately-consistent bits).
M.overrides_common = {
  MarkSignHL    = { fg = "#ff475f", bold = true },
  MarkSignNumHL = { fg = "#ff475f", bold = true },
  Search        = { bg = "#e8d4a8", fg = "#1e1e2e" },
  IncSearch     = { bg = "#f0a07a", fg = "#1e1e2e", bold = true },
  CurSearch     = { bg = "#f0a07a", fg = "#1e1e2e", bold = true },
  -- vim-sneak (plugins/sneak.lua): matches for f/F/t/T and s/S reuse the
  -- Search colors above so sneak targets read like search hits; label-mode
  -- letters pop in catppuccin mauve (the repo accent — bookmarks, lazygit).
  -- Sneak only defines its own defaults when these groups don't exist, and
  -- since it's lazy-loaded on the first motion, ours are always in place first.
  Sneak         = { bg = "#e8d4a8", fg = "#1e1e2e" },
  SneakCurrent  = { bg = "#f0a07a", fg = "#1e1e2e", bold = true },
  SneakLabel    = { bg = "#cba6f7", fg = "#11111b", bold = true },
  -- Mask hides the 2nd char of each label target: fg = bg = the label mauve.
  -- Sneak derives this from SneakLabel only inside its own init; pin it so it
  -- can never render as an unstyled/mismatched cell.
  SneakLabelMask = { bg = "#cba6f7", fg = "#cba6f7" },
  SneakScope    = { bg = "#45475a" }, -- catppuccin surface1: label-mode scope band
  -- Trouble windows aren't pinned by styler, so they use the global scheme —
  -- but most schemes link TroubleNormal to the (muted) NormalFloat, making the
  -- window look dim. Re-link to Normal so Trouble matches the editor on every
  -- scheme. (Native quickfix already uses Normal, so it needs nothing.)
  TroubleNormal   = { link = "Normal" },
  TroubleNormalNC = { link = "Normal" },
  -- Floating panels (LSP hover, diagnostics, previews, which-key, …): lift
  -- the panel off the code with a lighter background (catppuccin surface0)
  -- and trace the border in the repo's mauve accent, so a float reads as a
  -- box hovering ABOVE the buffer instead of blending into it. Forced on
  -- every scheme so the look is consistent regardless of styler's pin.
  -- Border in catppuccin teal — deliberately NOT the mauve accent, so the
  -- float's edge reads as its own thing against mauve-heavy UI (bookmarks,
  -- sneak labels) and clearly separates the box from the code behind it.
  NormalFloat = { bg = "#313244" },
  FloatBorder = { fg = "#94e2d5", bg = "#313244" },
  FloatTitle  = { fg = "#94e2d5", bg = "#313244", bold = true },
}

-- Per-scheme cursor / line-number / cursorline. Ordered list: the FIRST entry
-- whose Lua pattern matches the active scheme name wins, so put specific
-- patterns before broad ones (e.g. "^catppuccin%-latte" before "^catppuccin").
-- One entry covers a whole family of variants (all monokai-pro-* names, …).
M.overrides = {
  -- Monokai Pro — yellow accents (accent3 #ffd866) on warm bg #2d2a2e.
  { pat = "^monokai%-pro", hl = {
    Cursor       = { fg = "#2d2a2e", bg = "#ffd866" },
    lCursor      = { fg = "#2d2a2e", bg = "#ffd866" },
    CursorLine   = { bg = "#403e41" }, -- dimmed5: subtle warm band
    LineNr       = { fg = "#9a8c52" }, -- desaturated yellow, inactive lines
    CursorLineNr = { fg = "#ffd866", bold = true },
  } },

  -- TokyoNight (storm/moon, used by sh/tcl/make via styler) — the original
  -- navy/blue/pink set this file used to force globally, scoped to tokyonight.
  { pat = "^tokyonight", hl = {
    CursorLine   = { bg = "#143652" },
    LineNr       = { fg = "#5a8fa8" },
    CursorLineNr = { fg = "#ff79c6", bold = true },
  } },

  -- Add your future schemes here, e.g.:
  -- { pat = "^sd%-monokai%-catppuccin", hl = { LineNr = {...}, CursorLine = {...}, ... } },
}

-- Return the per-scheme hl table for a colorscheme name (nil if none matches).
function M.overrides_for(scheme)
  scheme = scheme or vim.g.colors_name or ""
  for _, e in ipairs(M.overrides) do
    if scheme:match(e.pat) then return e.hl end
  end
  return nil
end

-- Apply common + per-scheme overrides into highlight namespace `ns` for `scheme`.
function M.apply_overrides(ns, scheme)
  ns = ns or 0
  for group, spec in pairs(M.overrides_common) do
    vim.api.nvim_set_hl(ns, group, spec)
  end
  local hl = M.overrides_for(scheme)
  if hl then
    for group, spec in pairs(hl) do
      vim.api.nvim_set_hl(ns, group, spec)
    end
  end
end

-- Wire the overrides up: apply to the global scheme now + on every ColorScheme,
-- and into each styler per-filetype namespace as windows/filetypes appear.
-- styler loads its schemes into window-local namespaces named
-- "styler__<colorscheme>_<bg>" (note the DOUBLE underscore — styler concatenates
-- "styler_", the scheme, and the bg with "_", and its first element already ends
-- in "_") WITHOUT firing ColorScheme, so we parse the scheme back out of the
-- namespace name (`_+` eats both leading underscores) and apply its overrides.
function M.wire_overrides()
  M.apply_overrides(0, vim.g.colors_name)
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function(ev) M.apply_overrides(0, ev.match) end,
  })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    callback = function()
      vim.schedule(function()
        for name, ns in pairs(vim.api.nvim_get_namespaces()) do
          local scheme = name:match("^styler_+(.+)_[^_]*$")
          if scheme then M.apply_overrides(ns, scheme) end
        end
      end)
    end,
  })
end

-- Startup bootstrap: load the default colorscheme, then wire overrides. Called
-- once from colorschemes/tokyonight.lua (the eager priority-1000 plugin), after
-- its setup() — so tokyonight + monokai-pro (its dependency) are both ready.
function M.bootstrap()
  vim.cmd("colorscheme " .. M.default)
  M.wire_overrides()
end

-- Live styler state. Initialized false because styler genuinely isn't running
-- until its plugin loads — plugins/styler.lua calls enable_styler() at VeryLazy,
-- so per-filetype themes are ON by default moments after launch. <leader>uy /
-- :StylerToggle flips them off/on from there.
M.styler_enabled = false

-- Resume styler: (re)register its autocmds and re-pin every open window.
function M.enable_styler()
  require("styler").setup({ themes = M.styler_themes })
  M.styler_enabled = true
end

-- Suspend styler: drop its autocmds (so it stops re-pinning) and reset every
-- window back to the global namespace, so the global colorscheme shows
-- everywhere — the prerequisite for true full-window colorscheme previewing.
function M.disable_styler()
  pcall(vim.api.nvim_clear_autocmds, { group = "styler" })
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    pcall(vim.api.nvim_win_set_hl_ns, win, 0)
    if vim.w[win].theme then vim.w[win].theme = nil end
  end
  M.styler_enabled = false
end

function M.toggle_styler()
  if M.styler_enabled then M.disable_styler() else M.enable_styler() end
  vim.notify(
    "styler (per-filetype themes): " .. (M.styler_enabled and "ON" or "OFF"),
    vim.log.levels.INFO,
    { title = "theme" }
  )
end

-- Browse colorschemes with a live, full-window preview: turn styler off so the
-- preview reaches pinned windows too, then open Telescope's colorscheme picker.
-- On selection it reminds you how to make the choice permanent.
function M.browse()
  if M.styler_enabled then
    M.disable_styler()
    vim.notify(
      "styler off for browsing — <leader>uy to restore per-filetype themes",
      vim.log.levels.INFO,
      { title = "theme" }
    )
  end
  require("telescope.builtin").colorscheme({
    enable_preview = true,
    attach_mappings = function(_, _)
      local actions = require("telescope.actions")
      local state = require("telescope.actions.state")
      actions.select_default:replace(function(bufnr)
        local entry = state.get_selected_entry()
        actions.close(bufnr)
        if entry then
          vim.cmd("colorscheme " .. entry.value)
          vim.notify(
            "Set: " .. entry.value .. "\nMake it the default: set M.default in core/theme.lua",
            vim.log.levels.INFO,
            { title = "theme" }
          )
        end
      end)
      return true
    end,
  })
end

return M
