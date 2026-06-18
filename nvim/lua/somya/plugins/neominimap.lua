 return {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    -- auto_enable is false, so nothing renders until a toggle map is pressed.
    -- The keys below load it on demand; init (which sets vim.g.neominimap) still
    -- runs at startup, so config is in place before the plugin loads.
    cmd = "Neominimap",
    keys = {
      { "<leader>nm", "<cmd>Neominimap Toggle<CR>", desc = "Toggle minimap" },
      { "<leader>nf", "<cmd>Neominimap ToggleFocus<CR>", desc = "Toggle minimap focus" },
      { "<leader>nr", "<cmd>Neominimap Refresh<cr>", desc = "Refresh global minimap" },
    },
    init = function()
      vim.opt.sidescrolloff = math.max(vim.o.sidescrolloff, 36)
      vim.g.neominimap = {
        auto_enable = false,
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
