return {
  "NStefan002/screenkey.nvim",
  lazy = false,
  version = "*",
  keys = {
    {
      "<leader>sk",
      function()
        require("screenkey").toggle()
        vim.g.screenkey_active = not vim.g.screenkey_active
      end,
      desc = "Toggle screenkey display",
    },
  },
  opts = {
    win_opts = {
      row = vim.o.lines - vim.o.cmdheight - 1,
      col = vim.o.columns - 1,
      relative = "editor",
      anchor = "SE",
      width = 40,
      height = 3,
      border = "rounded",
      title = " Screenkey ",
      title_pos = "center",
      style = "minimal",
      focusable = false,
      noautocmd = true,
    },
    compress_after = 3,
    clear_after = 3,
    show_leader = true,
    group_mappings = false,
    disable = {
      filetypes = { "TelescopePrompt", "lazy", "mason" },
      buftypes = { "terminal", "prompt" },
    },
  },
}
