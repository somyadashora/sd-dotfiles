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
  -- Generic floating panels (previews, which-key, signature help, …) share
  -- the TERMINAL's "mint" identity (see toggleterm.lua): dark TEAL-tinted
  -- background + teal accents. Surface0 grey was tried first but reads too
  -- close to the editor bg — the teal hue makes "this is a panel, not the
  -- buffer" obvious at a glance, echoing the established convention that
  -- teal surfaces are "not the editor". Forced on every scheme + styler
  -- namespace. (Deliberately not mauve — that's the mark/label accent.
  -- The K hover, the glance peek, and the diagnostic float opt OUT of this
  -- family — they get their own "ember" / "dune" / "alert" identities below
  -- so each surface is recognizable.)
  NormalFloat = { bg = "#15241f" },
  FloatBorder = { fg = "#94e2d5", bg = "#15241f" },
  FloatTitle  = { fg = "#94e2d5", bg = "#15241f", bold = true },
  -- glance.nvim peek windows — the "dune" identity: Monokai's saturated
  -- amber/sand family on a dark desert-brown base. Deliberately a THIRD hue
  -- family, away from both the editor's pastels and the teal panel/terminal
  -- mint, so "am I in the peek?" answers itself and the peek's boundaries
  -- (amber rule lines + solid amber winbar pill, dashboard-box style) are
  -- unmissable. (Glance's auto theme — a subtle brighten of Normal — was too
  -- close to the editor; theme.enable is off in plugins/glance.lua, and
  -- glance's own defaults use default=true, so these explicit groups win.)
  -- Preview = warm brown; list = darker brown so the two halves read apart.
  -- The match groups matter: glance's defaults link them to Search, and our
  -- Search override is a bright sand BLOCK — on every list row that painted
  -- the sought signal as a screaming rectangle. List matches are amber-bold
  -- text instead; preview matches keep a contained warm band (there they mark
  -- occurrences to look at, not one-per-row noise).
  GlancePreviewNormal       = { bg = "#262019" },
  GlancePreviewCursorLine   = { bg = "#3a3122" },
  GlancePreviewLineNr       = { fg = "#8a7a4e" },
  GlancePreviewSignColumn   = { fg = "#262019" },
  GlancePreviewEndOfBuffer  = { bg = "#262019", fg = "#262019" },
  GlancePreviewBorderBottom = { fg = "#ffd866", bg = "#262019" },
  GlancePreviewMatch        = { bg = "#57451a", bold = true },
  GlanceListNormal          = { bg = "#1c1712", fg = "#e8ddc0" },
  GlanceListCursorLine      = { bg = "#3a3122" },
  GlanceListFilename        = { fg = "#ffd866", bold = true },
  GlanceListFilepath        = { fg = "#8a7a4e" },
  GlanceListCount           = { fg = "#c7a94f" },
  GlanceListMatch           = { fg = "#ffd866", bold = true },
  GlanceListEndOfBuffer     = { bg = "#1c1712", fg = "#1c1712" },
  GlanceListBorderBottom    = { fg = "#ffd866", bg = "#1c1712" },
  GlanceFoldIcon            = { fg = "#8a7a4e" },
  GlanceIndent              = { fg = "#3a3122" },
  GlanceWinBarFilename      = { fg = "#1a150c", bg = "#ffd866", bold = true },
  GlanceWinBarFilepath      = { fg = "#1a150c", bg = "#ffd866" },
  GlanceWinBarTitle         = { fg = "#1a150c", bg = "#ffd866", bold = true },
  GlanceBorderTop           = { fg = "#ffd866", bg = "#262019" },
  -- K hover float — the "ember" identity: dark COFFEE-brown base (clearly
  -- warm next to the navy editor — kanagawa-dragon's near-black charcoal was
  -- tried and read as "same colorscheme" at a glance), warm ivory body text,
  -- glowing gold border + solid gold " 󰋗 hover " title pill. The content is
  -- kanagawa-dragon re-accented VIVID WARM via surface_overrides.hover (red/
  -- orange/gold/green only — no teal, no pastels). Not set via NormalFloat
  -- (that would recolor every float): lsp/lspconfig.lua wraps
  -- vim.lsp.util.open_floating_preview and stamps hover floats (by focus_id)
  -- with a winhighlight mapping NormalFloat/FloatBorder/FloatTitle to these.
  SdHoverNormal = { fg = "#dcd7ba", bg = "#201511" },
  SdHoverBorder = { fg = "#ff9e3b", bg = "#201511" },
  SdHoverTitle  = { fg = "#201511", bg = "#ff9e3b", bold = true },
  -- gitsigns floating popups (preview_hunk, blame_line) — the "neon" identity,
  -- noice.nvim-inspired: electric cyan border + a solid neon title pill
  -- (noice's cmdline-popup look) on a near-black blue base, stamped onto the
  -- popup windows by the popup.create wrap in plugins/gitsigns.lua. The diff
  -- rows inside the hunk preview go neon too: saturated green/red text on
  -- same-hue tinted row bands instead of the scheme's washed DiffAdd/Delete.
  SdGitPopupNormal = { bg = "#0b1221" },
  SdGitPopupBorder = { fg = "#0db9d7", bg = "#0b1221" },
  SdGitPopupTitle  = { fg = "#0b1221", bg = "#0db9d7", bold = true },
  -- Diagnostic floats (<leader>d, the auto-float after ]d/[d) — the "alert"
  -- identity, same design language as the neon gitsigns popups: near-black
  -- plum base + border and solid title pill tinted by the WORST severity in
  -- the float (colors from the unified diagnostic accent set below), stamped
  -- by the open_floating_preview wrapper in lsp/lspconfig.lua. The message
  -- lines themselves are colored per-severity via the DiagnosticFloating*
  -- links, so the whole float reads "alert", not "editor".
  SdDiagNormal      = { bg = "#180f1d" },
  SdDiagBorderError = { fg = "#ff6188", bg = "#180f1d" },
  SdDiagBorderWarn  = { fg = "#ffd866", bg = "#180f1d" },
  SdDiagBorderInfo  = { fg = "#78dce8", bg = "#180f1d" },
  SdDiagBorderHint  = { fg = "#a9dc76", bg = "#180f1d" },
  SdDiagTitleError  = { fg = "#180f1d", bg = "#ff6188", bold = true },
  SdDiagTitleWarn   = { fg = "#180f1d", bg = "#ffd866", bold = true },
  SdDiagTitleInfo   = { fg = "#180f1d", bg = "#78dce8", bold = true },
  SdDiagTitleHint   = { fg = "#180f1d", bg = "#a9dc76", bold = true },
  GitSignsAddPreview    = { fg = "#50fa7b", bg = "#0d2818" },
  GitSignsDeletePreview = { fg = "#ff6188", bg = "#2d1220" },
  -- Diagnostics — one saturated Monokai accent set on EVERY scheme (the
  -- pastel per-scheme defaults washed out on the dark editor bg, and each
  -- styler filetype shipped different reds). Explicit Sign/Floating links
  -- because several schemes define those groups directly — a fg on the base
  -- group alone wouldn't reach them. Virtual text sits in dark same-hue pills
  -- so it reads as annotation, not code; underlines are undercurls colored
  -- via sp only, so syntax highlighting under them survives.
  DiagnosticError            = { fg = "#ff6188" },
  DiagnosticWarn             = { fg = "#ffd866" },
  DiagnosticInfo             = { fg = "#78dce8" },
  DiagnosticHint             = { fg = "#a9dc76" },
  DiagnosticSignError        = { link = "DiagnosticError" },
  DiagnosticSignWarn         = { link = "DiagnosticWarn" },
  DiagnosticSignInfo         = { link = "DiagnosticInfo" },
  DiagnosticSignHint         = { link = "DiagnosticHint" },
  DiagnosticFloatingError    = { link = "DiagnosticError" },
  DiagnosticFloatingWarn     = { link = "DiagnosticWarn" },
  DiagnosticFloatingInfo     = { link = "DiagnosticInfo" },
  DiagnosticFloatingHint     = { link = "DiagnosticHint" },
  DiagnosticVirtualTextError = { fg = "#ff6188", bg = "#33161d" },
  DiagnosticVirtualTextWarn  = { fg = "#ffd866", bg = "#332b14" },
  DiagnosticVirtualTextInfo  = { fg = "#78dce8", bg = "#142b30" },
  DiagnosticVirtualTextHint  = { fg = "#a9dc76", bg = "#1c2e14" },
  DiagnosticUnderlineError   = { undercurl = true, sp = "#ff6188" },
  DiagnosticUnderlineWarn    = { undercurl = true, sp = "#ffd866" },
  DiagnosticUnderlineInfo    = { undercurl = true, sp = "#78dce8" },
  DiagnosticUnderlineHint    = { undercurl = true, sp = "#a9dc76" },
  -- Git hunk signs (gitsigns, own statuscol column) — same saturated Monokai
  -- family, consistent across schemes: green add / amber change / red delete.
  -- Matches the diagnostic accents by design (one "signal color" vocabulary
  -- in the gutter); gitsigns derives its Staged* variants from these.
  GitSignsAdd          = { fg = "#a9dc76" },
  GitSignsChange       = { fg = "#ffd866" },
  GitSignsDelete       = { fg = "#ff6188" },
  GitSignsTopdelete    = { fg = "#ff6188" },
  GitSignsChangedelete = { fg = "#fc9867" },
  GitSignsUntracked    = { fg = "#78dce8" },
}

-- Per-scheme cursor / line-number / cursorline. Ordered list: the FIRST entry
-- whose Lua pattern matches the active scheme name wins, so put specific
-- patterns before broad ones (e.g. "^catppuccin%-latte" before "^catppuccin").
-- One entry covers a whole family of variants (all monokai-pro-* names, …).
M.overrides = {
  -- sd-monokai-catppuccin (M.default, and the styler theme for verilog/vhdl).
  -- The scheme pushes its background well below stock Catppuccin (#13131d) to
  -- make the pastels pop, but monokai-pro's CursorLine slot doesn't scale with
  -- it: it lands on #1c1d28, only ~+10 per channel above the background, which
  -- disappears on a dark panel. Every other scheme here clears +12 (catppuccin)
  -- to +42 (tokyonight). This lifts it to ~+17 — still a quiet band, not a
  -- highlight bar, but findable when you glance back at the editor.
  { pat = "^sd%-monokai%-catppuccin", hl = {
    CursorLine = { bg = "#232433" },
  } },

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

-- ── Italic comments: off ────────────────────────────────────────────────────
-- Most colorschemes here italicise comments (monokai-pro's styles.comment,
-- catppuccin/tokyonight/kanagawa defaults). That is a *rendering* hazard in a
-- terminal, not just a taste call: when the terminal font ships no true italic
-- face the emulator fakes one by slanting the upright glyphs. The slant
-- overhangs the right edge of the character cell, and whatever repaints the
-- next cell clips it — so the tail of a comment looks cut off, and it shifts
-- or flickers as the cursor moves across the line and forces redraws.
--
-- Rather than restate every scheme's comment colour, apply_overrides strips the
-- italic attribute back off whatever the scheme set — into ns 0 AND into every
-- styler per-filetype namespace, so .sv buffers obey too. Flip this to true if
-- you're on a terminal + font with a real italic face and want them back.
M.italic_comments = false

-- Groups de-italicised when M.italic_comments is false.
M.deitalic_groups = {
  "Comment", "SpecialComment",
  "@comment", "@comment.documentation",
  "@comment.error", "@comment.warning", "@comment.todo", "@comment.note",
  "@lsp.type.comment",
}

-- Strip `italic` from `group` in namespace `ns`, preserving every other attr.
-- nvim_get_hl on a non-zero ns returns only what that ns actually defines, so a
-- group the scheme left alone comes back empty and is skipped (ns 0 covers it).
local function deitalic(ns, group)
  local ok, hl = pcall(vim.api.nvim_get_hl, ns, { name = group, link = false })
  if not ok or type(hl) ~= "table" or next(hl) == nil then return end
  if not (hl.italic or (hl.cterm and hl.cterm.italic)) then return end
  hl.italic = false
  if hl.cterm then hl.cterm.italic = false end
  vim.api.nvim_set_hl(ns, group, hl)
end

-- Apply common + per-scheme overrides into highlight namespace `ns` for `scheme`.
function M.apply_overrides(ns, scheme)
  ns = ns or 0
  for group, spec in pairs(M.overrides_common) do
    vim.api.nvim_set_hl(ns, group, spec)
  end
  if not M.italic_comments then
    for _, group in ipairs(M.deitalic_groups) do
      deitalic(ns, group)
    end
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

-- ── Overlay-surface CONTENT schemes ─────────────────────────────────────────
-- The Glance*/SdHover* chrome above colors a surface's frame, but the CONTENT
-- (the .sv code in a glance preview, the markdown in a K hover) is highlighted
-- by whatever namespace the window uses — by default the pastel editor scheme
-- (styler even re-pins the peek window to the per-filetype pastel theme). To
-- make the content itself read "different mode", pin_surface() loads a real
-- NON-pastel colorscheme into a window-local namespace — reusing styler's own
-- loader, so the ns is built once and cached — and marks the window with
-- w.sd_surface so styler's per-filetype repinning (and clear) skips it (see
-- the guard in enable_styler). Saturated Monokai Pro variants, matching each
-- surface's chrome: ristretto's warm coffee tones under the dune amber,
-- classic's vivid accents under the ember orange.
M.surface_schemes = {
  glance = "monokai-pro-ristretto",
  -- kanagawa-dragon as the hover BASE: it has no teal/neon and no pastels
  -- anywhere (monokai-pro-classic was tried first — its cyan accent on
  -- types/functions read as "teal neon" in the code fences). Its muted ink
  -- accents are then re-colored vivid warm by surface_overrides.hover below;
  -- the base still supplies every group the override set doesn't name.
  hover  = "kanagawa-dragon",
}

-- Extra per-surface polish applied INTO the surface's namespace on top of the
-- content scheme (and BEFORE capture_backfill, so backfilled children inherit
-- these instead of the base scheme's colors). Keyed like surface_schemes.
M.surface_overrides = {
  -- The hover's vivid-warm syntax set: red / orange / gold / green only —
  -- hot hues on the coffee bg, unmistakably not the cool pastel editor.
  -- (kanagawa-dragon's own ink accents were too muted: at a glance the float
  -- read as "same colorscheme".)
  hover = {
    ["@comment"]          = { fg = "#8f7a67", italic = true },
    ["@keyword"]          = { fg = "#e46876", bold = true },
    ["@type"]             = { fg = "#ffa066" },
    ["@function"]         = { fg = "#e6c384" },
    ["@string"]           = { fg = "#98bb6c" },
    ["@number"]           = { fg = "#ff9e3b" },
    ["@boolean"]          = { fg = "#ff9e3b" },
    ["@constant"]         = { fg = "#ffa066" },
    ["@operator"]         = { fg = "#ff9e3b" },
    ["@variable"]         = { fg = "#dcd7ba" },
    ["@variable.builtin"] = { fg = "#e46876", italic = true },
    ["@property"]         = { fg = "#dcd7ba" },
    ["@punctuation"]      = { fg = "#a6927b" },
    -- Markdown structure in gold, echoing the ember border; inline code on a
    -- lifted warm chip so identifiers pop out of prose. (Hover floats
    -- highlight via treesitter markdown — @markup.* — Title is the legacy path.)
    ["@markup.heading"] = { fg = "#ff9e3b", bold = true },
    Title               = { fg = "#ff9e3b", bold = true },
    ["@markup.raw"]     = { fg = "#e6c384", bg = "#2a1f18" },
    ["@markup.link"]    = { fg = "#ffa066", underline = true },
    ["@markup.strong"]  = { fg = "#ffa066", bold = true },
  },
}

-- Treesitter captures resolve in the window's namespace FIRST — but schemes
-- like kanagawa define only the @groups they restyle and lean on nvim's
-- default links (@keyword → Keyword, @keyword.return → @keyword, …) for the
-- rest. Those defaults live in the GLOBAL namespace, so inside a pinned
-- surface any undefined capture falls back to the pastel editor scheme.
-- Backfill: for this common capture set, define an in-ns link to the first
-- listed target the scheme DID define, so resolution never leaves the ns.
-- Ordered parents-before-children (children may link to the parent capture).
-- No-ops for schemes that define every capture themselves (monokai-pro).
M.capture_backfill = {
  { "@comment", "Comment" },
  { "@keyword", "Keyword", "Statement" },
  { "@keyword.conditional", "Conditional", "@keyword" },
  { "@keyword.repeat", "Repeat", "@keyword" },
  { "@keyword.return", "@keyword" },
  { "@keyword.function", "@keyword" },
  { "@keyword.operator", "Operator", "@keyword" },
  { "@keyword.import", "Include", "@keyword" },
  { "@keyword.exception", "Exception", "@keyword" },
  { "@keyword.modifier", "@keyword" },
  { "@keyword.type", "@keyword" },
  { "@keyword.directive", "PreProc" },
  { "@keyword.directive.define", "Define", "PreProc" },
  { "@type", "Type" },
  { "@type.builtin", "@type" },
  { "@type.definition", "Typedef", "@type" },
  { "@function", "Function" },
  { "@function.builtin", "Special", "@function" },
  { "@function.call", "@function" },
  { "@function.macro", "Macro", "@function" },
  { "@function.method", "@function" },
  { "@function.method.call", "@function" },
  { "@constructor", "Special" },
  { "@variable", "Identifier" },
  { "@variable.builtin", "Special", "@variable" },
  { "@variable.parameter", "@variable" },
  { "@variable.member", "@variable" },
  { "@property", "Identifier" },
  { "@constant", "Constant" },
  { "@constant.builtin", "Special", "@constant" },
  { "@constant.macro", "Macro", "@constant" },
  { "@module", "Include", "Identifier" },
  { "@label", "Label" },
  { "@string", "String" },
  { "@string.escape", "SpecialChar", "@string" },
  { "@string.special", "SpecialChar", "@string" },
  { "@string.regexp", "@string" },
  { "@character", "Character", "@string" },
  { "@number", "Number" },
  { "@number.float", "Float", "@number" },
  { "@boolean", "Boolean", "Constant" },
  { "@operator", "Operator" },
  { "@punctuation.bracket", "Delimiter" },
  { "@punctuation.delimiter", "Delimiter" },
  { "@punctuation.special", "Special" },
  { "@attribute", "PreProc" },
  { "@tag", "Tag" },
}

-- Namespaces already backfilled (keyed by ns id) — the work is per-ns, not
-- per-window, so it runs once per content scheme per session.
M._ns_backfilled = {}

-- Pin `win` to the content scheme for `surface` ("glance" | "hover").
-- Degrades gracefully: without styler.nvim the surface keeps its chrome
-- identity and the content simply stays on the active scheme.
function M.pin_surface(win, surface)
  local scheme = M.surface_schemes[surface]
  if not scheme or not win or not vim.api.nvim_win_is_valid(win) then return end
  if vim.w[win].sd_surface == surface then return end
  local ok, loader = pcall(require, "styler.theme")
  if not ok then return end
  local lok, ns = pcall(loader.load, { colorscheme = scheme })
  if not lok or type(ns) ~= "number" then return end
  -- The chrome groups (Glance*, SdHover*, …) must exist INSIDE this ns too —
  -- winhighlight remaps resolve in the window's namespace first. Idempotent
  -- and cheap (a few dozen set_hl), and only runs on surface open.
  M.apply_overrides(ns, scheme)
  -- Surface overrides go in BEFORE the backfill: children the backfill fills
  -- (@type.builtin, @keyword.return, …) copy attrs from their parent capture,
  -- which must already carry the surface's colors, not the base scheme's.
  for group, spec in pairs(M.surface_overrides[surface] or {}) do
    vim.api.nvim_set_hl(ns, group, spec)
  end
  if not M._ns_backfilled[ns] then
    -- Copy the target's CONCRETE attrs (following in-ns link chains) rather
    -- than planting a link: draw-time link resolution inside a namespace can
    -- escape to the global scheme, which is the leak being fixed.
    local function ns_attrs(name, depth)
      local hl = vim.api.nvim_get_hl(ns, { name = name })
      if hl.link and depth < 10 then return ns_attrs(hl.link, depth + 1) end
      return (not hl.link and not vim.tbl_isempty(hl)) and hl or nil
    end
    for _, spec in ipairs(M.capture_backfill) do
      if vim.tbl_isempty(vim.api.nvim_get_hl(ns, { name = spec[1] })) then
        for i = 2, #spec do
          local attrs = ns_attrs(spec[i], 0)
          if attrs then
            vim.api.nvim_set_hl(ns, spec[1], attrs)
            break
          end
        end
      end
    end
    M._ns_backfilled[ns] = true
  end
  vim.w[win].sd_surface = surface
  vim.api.nvim_win_set_hl_ns(win, ns)
end

-- Live styler state. Initialized false because styler genuinely isn't running
-- until its plugin loads — plugins/styler.lua calls enable_styler() at VeryLazy,
-- so per-filetype themes are ON by default moments after launch. <leader>uy /
-- :StylerToggle flips them off/on from there.
M.styler_enabled = false

-- Resume styler: (re)register its autocmds and re-pin every open window.
function M.enable_styler()
  local styler = require("styler")
  -- One-time guard: surface-pinned windows (w.sd_surface, set by pin_surface)
  -- are off-limits to styler — its update() runs on FileType/BufWinEnter/
  -- WinNew/OptionSet-winhighlight and would repin the glance preview to the
  -- per-filetype pastel theme (and clear() would unpin surfaces whose ft has
  -- no styler entry) moments after we pin it.
  if not M._styler_guarded then
    local set_theme, clear = styler.set_theme, styler.clear
    styler.set_theme = function(win, theme)
      local w = (not win or win == 0) and vim.api.nvim_get_current_win() or win
      if vim.w[w].sd_surface then return end
      return set_theme(win, theme)
    end
    styler.clear = function(win)
      local w = (not win or win == 0) and vim.api.nvim_get_current_win() or win
      if vim.w[w].sd_surface then return end
      return clear(win)
    end
    M._styler_guarded = true
  end
  styler.setup({ themes = M.styler_themes })
  M.styler_enabled = true
end

-- Suspend styler: drop its autocmds (so it stops re-pinning) and reset every
-- window back to the global namespace, so the global colorscheme shows
-- everywhere — the prerequisite for true full-window colorscheme previewing.
function M.disable_styler()
  pcall(vim.api.nvim_clear_autocmds, { group = "styler" })
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    -- Surface windows (glance peek, hover float) keep their pinned content
    -- scheme — they're overlay surfaces, not part of the per-filetype theming
    -- this toggle controls.
    if not vim.w[win].sd_surface then
      pcall(vim.api.nvim_win_set_hl_ns, win, 0)
      if vim.w[win].theme then vim.w[win].theme = nil end
    end
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
