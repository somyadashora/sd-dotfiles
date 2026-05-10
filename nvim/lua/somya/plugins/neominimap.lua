 return {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    lazy = false,
    keys = {
      { "<leader>nm", "<cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
      { "<leader>nf", "<cmd>Neominimap ToggleFocus<CR>", desc = "Toggle minimap focus" },
    },
    init = function()
      vim.opt.sidescrolloff = math.max(vim.o.sidescrolloff, 36)
      vim.g.neominimap = {
        auto_enable = true,
        layout = "float",
        float = { minimap_width = 16 },
        diagnostic = { enabled = true, mode = "line" },
        git = { enabled = true, mode = "sign" },
        treesitter = { enabled = true },
        fold = { enabled = true },
        search = { enabled = true, mode = "line" },
        mark = { enabled = false },
        exclude_filetypes = { "NvimTree", "TelescopePrompt", "lazy", "mason", "help" },
        exclude_buftypes = { "nofile", "nowrite", "quickfix", "terminal", "prompt" },
      }
    end,
  }
