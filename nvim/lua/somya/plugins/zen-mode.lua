return {
  "folke/zen-mode.nvim",
  keys = {
    { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen mode" },
  },
  opts = {
    window = {
      width = 120, -- columns of editable text; surrounding space is padded
      options = {
        -- Keep the gutter we rely on: hybrid line numbers, plus marks and git
        -- signs. Marks/git are drawn by statuscol.nvim (which reads them from
        -- extmarks and sizes its own gutter), so signcolumn stays "no" to match
        -- the global setting -- statuscol still renders them.
        number = true,
        relativenumber = true,
        cursorline = true,
        signcolumn = "no",
      },
    },
    plugins = {
      options = { laststatus = 0 }, -- hide the lualine statusline
      -- The gitsigns integration only runs when enabled=true (and it HIDES the
      -- signs). Keep it false so git signs stay visible in Zen mode.
      gitsigns = { enabled = false },
    },
  },
}
