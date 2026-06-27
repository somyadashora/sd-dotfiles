return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 700
  end,
  opts = {
    -- Inside a quickfix/loclist window, the global `z*` maps (folds, scrolls) are
    -- useless clutter — hide them so only nvim-bqf's buffer-local quickfix `z`
    -- actions (zn/zN/z<Tab>/zf/zp/zo) show. Global maps arrive here without a
    -- buffer field; bqf's are buffer-local, so we only drop the global ones.
    filter = function(mapping)
      if vim.bo.buftype == "quickfix"
        and type(mapping.lhs) == "string"
        and mapping.lhs:match("^z")
        and (not mapping.buffer or mapping.buffer == 0)
      then
        return false
      end
      return true
    end,
    -- Name every <leader> prefix that fans out into multiple keybindings, so the
    -- popup shows e.g. "+Cursor" instead of a bare "c  →  +9 keymaps". Easy to
    -- forget what the less-used prefixes do otherwise. (mode defaults to normal,
    -- which is where the <leader> menu is used.) Add a row here whenever a new
    -- prefix grows a second binding.
    spec = {
      { "<leader>A", group = "Align" },
      { "<leader>S", group = "Spell" },
      { "<leader>T", group = "Tabs" },
      { "<leader>b", group = "Buffers" },
      { "<leader>bc", group = "Close buffers" }, -- nested under Buffers
      { "<leader>c", group = "Cursor" }, -- smear-cursor presets/colors
      { "<leader>e", group = "Explorer" }, -- nvim-tree
      { "<leader>f", group = "Find" }, -- telescope
      { "<leader>h", group = "Git hunks" }, -- gitsigns stage/reset/preview/blame
      { "<leader>l", group = "Lint & LazyGit" },
      { "<leader>m", group = "Multi-cursor" }, -- vim-visual-multi
      { "<leader>n", group = "Minimap & search" },
      { "<leader>o", group = "Outline" }, -- aerial symbol outline
      { "<leader>q", group = "Quickfix" },
      { "<leader>r", group = "Code review" }, -- code-review.nvim comments
      { "<leader>s", group = "Splits & windows" },
      { "<leader>t", group = "Terminal" },
      { "<leader>u", group = "UI / Theme" }, -- styler toggle + colorscheme browse
      { "<leader>v", group = "LSP / Code" }, -- generic LSP actions + slang-only cone tracing
      { "<leader>w", group = "Session" }, -- auto-session
      { "<leader>x", group = "Trouble & diagnostics" },
    },
  },
}
