return {
  "folke/zen-mode.nvim",
  keys = {
    { "<leader>z", "<cmd>ZenMode<CR>", desc = "Toggle Zen mode" },
  },
  opts = {
    window = {
      width = 120, -- columns of editable text; surrounding space is padded
      options = {
        number = false,
        relativenumber = false,
        signcolumn = "no",
        cursorline = false,
      },
    },
    plugins = {
      options = { laststatus = 0 }, -- hide the lualine statusline
      gitsigns = { enabled = false },
    },
  },
}
