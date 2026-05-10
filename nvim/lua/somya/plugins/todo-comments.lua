return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("todo-comments").setup({
      keywords = {
        FIXME = {
          color = "error",
          alt = { "FIX" },
          icon = " ",
        },
        TODO = { icon = " ", color = "info" },
        REVIEW = { icon = " ", color = "warning", alt = { "WARNING" } },
        PERF = { icon = " ", alt = { "IMPORTANT" } },
        SPEC = { icon = "󰦨 ", alt = { "SPECIFICATION" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
    })

    local keymap = vim.keymap
    keymap.set("n", "]t", function()
      require("todo-comments").jump_next()
    end, { desc = "Next todo comment" })
    keymap.set("n", "[t", function()
      require("todo-comments").jump_prev()
    end, { desc = "Previous todo comment" })
  end,
}
