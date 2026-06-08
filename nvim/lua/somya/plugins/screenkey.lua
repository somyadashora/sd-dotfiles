local function win_opts()
  return {
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
  }
end

local base_opts = {
  compress_after = 3,
  clear_after = 3,
  show_leader = true,
  group_mappings = false,
  disable = {
    filetypes = { "TelescopePrompt", "lazy", "mason" },
    buftypes = { "terminal", "prompt" },
  },
}

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
  config = function()
    require("screenkey").setup(vim.tbl_extend("force", base_opts, { win_opts = win_opts() }))

    vim.api.nvim_create_autocmd("VimResized", {
      callback = function()
        if vim.g.screenkey_active then
          require("screenkey").toggle()
          require("screenkey").setup(vim.tbl_extend("force", base_opts, { win_opts = win_opts() }))
          require("screenkey").toggle()
        end
      end,
    })
  end,
}
