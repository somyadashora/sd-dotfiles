-- Terminal color schemes, cycled at runtime with <leader>tc.
-- Each entry is a compact spec; `scheme_highlights` expands it into the
-- per-element highlight table toggleterm applies window-locally (winhighlight):
--   bg     window background          fg     normal text
--   accent border + active statusline muted  inactive statusline / winbar
-- Colors are catppuccin-based so the dark/light pairs feel consistent. The
-- terminal must read clearly as "not the editor" (a cool navy #001424 tokyonight).
local schemes = {
  { name = "mint",     bg = "#15241f", fg = "#cdd6f4", accent = "#94e2d5", muted = "#5a8fa8" }, -- Teal (default)
  { name = "espresso", bg = "#2c211a", fg = "#cdd6f4", accent = "#fab387", muted = "#9d7e68" }, -- Peach
  { name = "purple",   bg = "#2a1d3d", fg = "#cdd6f4", accent = "#cba6f7", muted = "#7f7095" }, -- Mauve
  { name = "rose",     bg = "#2b1a26", fg = "#cdd6f4", accent = "#f5c2e7", muted = "#9a6f8a" }, -- Pink
  { name = "lavender", bg = "#1f1d3a", fg = "#cdd6f4", accent = "#b4befe", muted = "#6f72a0" }, -- Lavender
  { name = "maroon",   bg = "#2c1a1d", fg = "#cdd6f4", accent = "#eba0ac", muted = "#9a6f76" }, -- Maroon
  { name = "gold",     bg = "#262214", fg = "#cdd6f4", accent = "#f9e2af", muted = "#9c8f5e" }, -- Yellow
}

local function scheme_highlights(s)
  return {
    Normal       = { guibg = s.bg, guifg = s.fg },
    NormalFloat  = { guibg = s.bg, guifg = s.fg },
    FloatBorder  = { guibg = s.bg, guifg = s.accent },
    StatusLine   = { guibg = s.bg, guifg = s.accent },
    StatusLineNC = { guibg = s.bg, guifg = s.muted },
    WinBar       = { guibg = s.bg, guifg = s.accent },
    WinBarNC     = { guibg = s.bg, guifg = s.muted },
  }
end

-- Cycle to scheme `idx` (1-based, wraps). Recolors already-open terminals
-- immediately and updates toggleterm's config so new terminals + its ColorScheme
-- re-apply use the new scheme too.
local current = 1
local function apply_scheme(idx)
  current = (idx - 1) % #schemes + 1
  local s = schemes[current]
  local hls = scheme_highlights(s)

  -- keep future-created terminals and toggleterm's own ColorScheme handler in sync
  local ok, ttconfig = pcall(require, "toggleterm.config")
  if ok then
    ttconfig.highlights = vim.tbl_deep_extend("force", ttconfig.highlights or {}, hls)
  end

  -- Recolor open terminals now. toggleterm's winhighlight already maps each
  -- element to a "ToggleTerm<id><Element>" group; we just redefine those groups.
  -- (We set them directly rather than via hl_term, whose default=true would
  -- refuse to overwrite the previous scheme's already-defined groups.)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local wh = vim.wo[win].winhighlight or ""
    if wh:find("ToggleTerm") then
      for src, dst in wh:gmatch("(%w+):(ToggleTerm%w+)") do
        local spec = hls[src]
        if spec then
          vim.api.nvim_set_hl(0, dst, { fg = spec.guifg, bg = spec.guibg })
        end
      end
    end
  end

  vim.notify("Terminal colorscheme: " .. s.name, vim.log.levels.INFO)
end

return {
  "akinsho/toggleterm.nvim",
  version = "*",
  -- lazy-load on first <leader>t keypress or the :ToggleTerm command
  cmd = { "ToggleTerm", "ToggleTermToggleAll" },
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal (last used)" },
    { "<leader>tf", "<cmd>2ToggleTerm direction=float<cr>", desc = "Floating terminal" },
    { "<leader>th", "<cmd>3ToggleTerm direction=horizontal size=15<cr>", desc = "Bottom (horizontal) terminal" },
    { "<leader>tv", "<cmd>4ToggleTerm direction=vertical size=80<cr>", desc = "Vertical terminal" },
    { "<leader>ta", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle all terminals" },
    { "<leader>tc", function() apply_scheme(current + 1) end, desc = "Cycle terminal colorscheme" },
  },
  opts = {
    -- default geometry for horizontal/vertical splits
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
    direction = "float", -- default for <leader>tt
    float_opts = {
      border = "curved",
      winblend = 0,
    },
    start_in_insert = true,
    persist_size = true,
    persist_mode = true,
    -- Distinct background so the terminal is recognizable against the navy editor.
    -- Applied window-locally (winhighlight) so it doesn't leak into normal buffers;
    -- toggleterm re-applies on ColorScheme, surviving styler.nvim's colorscheme
    -- reload. Cycle between `schemes` at runtime with <leader>tc.
    shade_terminals = false,
    highlights = scheme_highlights(schemes[current]),
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- Terminal-mode mappings (buffer-local to terminal buffers).
    -- `jk` mirrors the insert-mode jk->ESC habit; <esc> is left untouched so
    -- TUI apps (fzf, htop, lazygit) keep working inside a terminal.
    local function set_terminal_keymaps()
      local kopts = { buffer = 0, silent = true }
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], kopts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], kopts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], kopts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], kopts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], kopts)
    end

    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*toggleterm#*",
      callback = set_terminal_keymaps,
    })
  end,
}
