return {
    "chentoast/marks.nvim",
    event = "VeryLazy",
    opts = {
      default_mappings = true,
      builtin_marks = { ".", "<", ">", "^", "[", "]", "'"},
      cyclic = true,
      sign_priority = { lower = 15, upper = 20, builtin = 12, bookmark = 25 },
    },
  }
