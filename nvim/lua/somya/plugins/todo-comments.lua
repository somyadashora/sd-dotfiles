return {
  "folke/todo-comments.nvim",
  -- Highlights need to be active when a file opens; defer to first buffer read
  -- rather than startup. (Also loads as a telescope/trouble dependency.)
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("todo-comments").setup({
      highlight = {
        pattern = [[.*<(KEYWORDS)\s*:?]], -- match with or without colon
      },
      search = {
        pattern = [[\b(KEYWORDS):?]], -- match with or without colon
      },
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
