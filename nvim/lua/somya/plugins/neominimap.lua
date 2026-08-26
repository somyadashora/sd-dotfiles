 return {
    "Isrothy/neominimap.nvim",
    version = "v3.x.x",
    -- auto_enable is false, so nothing renders until a toggle map is pressed.
    -- The keys below load it on demand; init (which sets vim.g.neominimap) still
    -- runs at startup, so config is in place before the plugin loads.
    cmd = "Neominimap",
    keys = {
      -- The minimap is a FLOAT: it overlays the right edge of the window rather
      -- than splitting it, so text under it is simply hidden. neominimap's own
      -- fix is a large 'sidescrolloff' that stops the cursor from wandering
      -- under the float. That reservation used to be set globally at startup
      -- (core/options.lua), which meant every nowrap buffer paid for it whether
      -- or not the minimap was up: the whole buffer slid sideways a column per
      -- h/l step for the outer 36 columns. Raise it here on toggle-on, put the
      -- normal value back on toggle-off.
      {
        "<leader>nm",
        function()
          local on = not vim.g.sd_minimap_on
          vim.g.sd_minimap_on = on
          if on then
            vim.g.sd_sso_saved = vim.o.sidescrolloff
            -- float width + a little slack, not the README's blanket 36
            vim.o.sidescrolloff = math.max(vim.o.sidescrolloff, 20)
          else
            vim.o.sidescrolloff = vim.g.sd_sso_saved or 8
          end
          vim.cmd("Neominimap Toggle")
        end,
        desc = "Toggle minimap",
      },
      { "<leader>nf", "<cmd>Neominimap ToggleFocus<CR>", desc = "Toggle minimap focus" },
      { "<leader>nr", "<cmd>Neominimap Refresh<cr>", desc = "Refresh global minimap" },
    },
    init = function()
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
