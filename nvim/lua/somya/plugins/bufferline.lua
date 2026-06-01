return {
  "akinsho/bufferline.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    -- scopes buffers to the tab they were opened in
    { "tiagovla/scope.nvim", config = true },
  },
  version = "*",
  config = function()
    require("bufferline").setup({
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
    })

    local keymap = vim.keymap
    keymap.set("n", "<leader>bg",  "<cmd>BufferLinePick<cr>",        { desc = "Pick buffer by letter" })
    keymap.set("n", "<leader>bn",  "<cmd>BufferLineCycleNext<cr>",   { desc = "Next buffer" })
    keymap.set("n", "<leader>bp",  "<cmd>BufferLineCyclePrev<cr>",   { desc = "Prev buffer" })
    keymap.set("n", "<leader>bcr", "<cmd>BufferLineCloseRight<cr>",  { desc = "Close buffers to the right" })
    keymap.set("n", "<leader>bcl", "<cmd>BufferLineCloseLeft<cr>",   { desc = "Close buffers to the left" })
    keymap.set("n", "<leader>bco", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
    keymap.set("n", "<leader>bC",  "<cmd>BufferLinePickClose<cr>",   { desc = "Pick buffer to close" })
  end,
}
