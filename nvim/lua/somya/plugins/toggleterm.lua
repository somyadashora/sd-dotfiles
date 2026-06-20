return {
  "akinsho/toggleterm.nvim",
  version = "*",
  -- lazy-load on first <leader>T keypress or the :ToggleTerm command
  cmd = { "ToggleTerm", "ToggleTermToggleAll" },
  keys = {
    { "<leader>Tt", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal (last used)" },
    { "<leader>Tf", "<cmd>2ToggleTerm direction=float<cr>", desc = "Floating terminal" },
    { "<leader>Th", "<cmd>3ToggleTerm direction=horizontal size=15<cr>", desc = "Bottom (horizontal) terminal" },
    { "<leader>Tv", "<cmd>4ToggleTerm direction=vertical size=80<cr>", desc = "Vertical terminal" },
    { "<leader>Ta", "<cmd>ToggleTermToggleAll<cr>", desc = "Toggle all terminals" },
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
    direction = "float", -- default for <leader>Tt
    float_opts = {
      border = "curved",
      winblend = 0,
    },
    start_in_insert = true,
    persist_size = true,
    persist_mode = true,
    -- A dark-but-distinct mint/teal background + catppuccin Teal border so the
    -- terminal is immediately recognizable against the cool navy (#001424)
    -- tokyonight editor. The green hue reads clearly as "not the editor" (the
    -- editor is blue). Colors are catppuccin-mocha based: Teal #94e2d5 border,
    -- Text #cdd6f4 fg, over a dark mint base. Applied window-locally
    -- (winhighlight) so they don't leak into normal buffers; toggleterm re-applies
    -- them on ColorScheme, surviving styler.nvim's colorscheme-reload cycle.
    shade_terminals = false,
    highlights = {
      Normal = { guibg = "#15241f", guifg = "#cdd6f4" },
      NormalFloat = { guibg = "#15241f", guifg = "#cdd6f4" },
      FloatBorder = { guifg = "#94e2d5", guibg = "#15241f" },
      StatusLine = { guibg = "#15241f", guifg = "#94e2d5" },
      StatusLineNC = { guibg = "#15241f", guifg = "#5a8fa8" },
      WinBar = { guibg = "#15241f", guifg = "#94e2d5" },
      WinBarNC = { guibg = "#15241f", guifg = "#5a8fa8" },
    },
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
