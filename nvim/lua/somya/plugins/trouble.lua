return {
  "folke/trouble.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  cmd = "Trouble",
  opts = {
    focus = true, -- focus the Trouble window when it opens
    warn_no_results = false, -- don't nag when a source has nothing to show
    -- Everything else uses Trouble's (good) defaults:
    --   auto_preview  → preview the item under the cursor in the MAIN editor
    --   auto_refresh  → list stays in sync with its source (LSP, qf, …)
    --   follow        → list follows your cursor position
    --   restore       → reopen a mode at its last position
    -- In-window keys (buffer-local, see <leader>fH cheatsheet): <cr> jump,
    --   o jump+close, <c-s>/<c-v> split/vsplit, dd / visual-d delete item,
    --   }/]] next, {/[[ prev, p preview, P toggle preview, zo/zc fold.
  },
  keys = {
    { "<leader>xw", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (document)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols outline (right)" },
    { "<leader>xr", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP defs/refs/impls (right)" },
    { "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix list (Trouble view)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble view)" },
    { "<leader>xt", "<cmd>Trouble todo toggle filter.buf=0<cr>", desc = "Todos (document)" },
    { "<leader>xT", "<cmd>Trouble todo toggle<cr>", desc = "Todos (workspace)" },
  },
}
