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
--      locally (see M.styler_themes). This is why `:colorscheme X` changes the
--      file explorer but NOT a .sv/.py buffer — that window is pinned by styler.
--
-- To browse freely (preview reaching every window), turn styler off first:
-- <leader>uc does this for you, or toggle with <leader>uy / :StylerToggle.
-- Once you find a winner, lock it in by editing M.default below.

local M = {}

-- ── Single source of truth: the startup colorscheme ────────────────────────
-- Edit this one line to change the default applied on `nvim` launch.
M.default = "tokyonight"

-- ── styler.nvim: per-filetype window-local colorschemes ─────────────────────
M.styler_themes = {
  -- Hardware description languages
  systemverilog = { colorscheme = "monokai-pro-spectrum" },
  verilog       = { colorscheme = "monokai-pro-spectrum" },
  vhdl          = { colorscheme = "monokai-pro-spectrum" },

  -- Scripting / general purpose
  python        = { colorscheme = "catppuccin-frappe" },
  sh            = { colorscheme = "tokyonight-storm" },
  bash          = { colorscheme = "tokyonight-storm" },
  tcl           = { colorscheme = "tokyonight-moon" },

  -- Build / config
  make          = { colorscheme = "tokyonight-moon" },

  -- Markdown
  markdown      = { colorscheme = "catppuccin-frappe" },

  -- Git
  gitcommit     = { colorscheme = "catppuccin-latte" },
  gitconfig     = { colorscheme = "catppuccin-latte" },
  gitrebase     = { colorscheme = "catppuccin-latte" },
}

M.styler_enabled = true

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
