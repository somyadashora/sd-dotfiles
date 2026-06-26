return {
  "akinsho/bufferline.nvim",
  -- Lazy: UI element, load just after startup instead of blocking it. Also
  -- defers its scope.nvim dependency (~6ms) off the critical path.
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- scopes buffers to the tab they were opened in
    { "tiagovla/scope.nvim", config = true },
  },
  version = "*",
  config = function()
    local opts = {
      options = {
        mode                 = "buffers",
        separator_style      = "slant",
        always_show_bufferline = true,
        show_buffer_icons    = true,
        color_icons          = true,
        buffer_close_icon    = "󰅖",
        close_icon           = "󰅖",
        modified_icon        = "●",
        offsets = {
          {
            filetype  = "NvimTree",
            text      = "File Explorer",
            text_align = "left",
            separator = true,
          },
        },
      },
    }

    require("bufferline").setup(opts)

    -- bufferline derives its highlights from the colorscheme only at setup time,
    -- so re-run setup on every colorscheme switch to keep the tabline in sync.
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("BufferlineFollowColorscheme", { clear = true }),
      callback = function() require("bufferline").setup(opts) end,
    })

    local keymap = vim.keymap
    keymap.set("n", "<S-h>",       "<cmd>BufferLineCyclePrev<cr>",   { desc = "Prev buffer" })
    keymap.set("n", "<S-l>",       "<cmd>BufferLineCycleNext<cr>",   { desc = "Next buffer" })
    keymap.set("n", "<leader>bg",  "<cmd>BufferLinePick<cr>",        { desc = "Pick buffer by letter" })
    keymap.set("n", "<leader>bn",  "<cmd>BufferLineCycleNext<cr>",   { desc = "Next buffer" })
    keymap.set("n", "<leader>bp",  "<cmd>BufferLineCyclePrev<cr>",   { desc = "Prev buffer" })
    keymap.set("n", "<leader>bcr", "<cmd>BufferLineCloseRight<cr>",  { desc = "Close buffers to the right" })
    keymap.set("n", "<leader>bcl", "<cmd>BufferLineCloseLeft<cr>",   { desc = "Close buffers to the left" })
    keymap.set("n", "<leader>bco", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
    keymap.set("n", "<leader>bC",  "<cmd>BufferLinePickClose<cr>",   { desc = "Pick buffer to close" })
  end,
}
