return {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local ft = require("Comment.ft")
      ft.set("systemverilog", "// %s")
      ft.set("verilog", "// %s")
      ft.set("make", "# %s")
      ft.set("sh", "# %s")
      ft.set("bash", "# %s")
      ft.set("gitcommit", "# %s")
      ft.set("tcl", "# %s")

      require("Comment").setup({})
    end,
  }
