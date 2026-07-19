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
    -- Rows show the source line as-is, and RTL alignment padding (e.g.
    -- "output logic          abc;") wastes most of a sidebar row. Squeeze
    -- whitespace runs in the displayed text — the {text:ts} treesitter
    -- highlight is applied to the returned string, so coloring survives.
    -- Display-only: jumps use the item's position, not the text.
    formatters = {
      text = function(ctx)
        local text = vim.trim(tostring(ctx.item.text or "")):gsub("%s+", " ")
        return { text = text }
      end,
    },
    modes = {
      -- Every LSP row's default format ends in "({item.client})" — pure noise
      -- here, since only one SV server is ever active (:UseSlang/:UseVerible).
      -- All lsp_* sections inherit from lsp_base, so drop it once.
      lsp_base = {
        format = "{text:ts} {pos}",
      },
      -- The lsp mode (<leader>xr) lists defs/refs/impls with a code-line per
      -- entry, so the default sidebar width truncates almost everything —
      -- unlike symbols (<leader>xs), which is just names. Give it 40% of the
      -- editor (no wrap — squeezed one-line rows read better than wrapped ones).
      -- TEMPORARILY disabled: the default sections also include incoming/
      -- outgoing calls, but slang-server (<= 0.2.8) fills call-hierarchy items
      -- with (0,0) range/selectionRange, so Trouble renders line 1 of the file
      -- (a ///// banner) for every entry. Waiting on an upstream bugfix
      -- (hudson-trading/slang-server — "Call hierarchy items have (0,0)
      -- range/selectionRange and undeduplicated cone leaves"); once fixed,
      -- re-add "lsp_incoming_calls" / "lsp_outgoing_calls" below. Until then
      -- <leader>vd/vl cover cone tracing properly (lsp/lspconfig.lua).
      lsp = {
        win = { position = "right", size = 0.4 },
        sections = {
          "lsp_definitions",
          "lsp_references",
          "lsp_implementations",
          "lsp_type_definitions",
          "lsp_declarations",
        },
      },
    },
  },
  keys = {
    { "<leader>xw", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (workspace)" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (document)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols outline (right)" },
    { "<leader>xr", "<cmd>Trouble lsp toggle focus=false<cr>", desc = "LSP defs/refs/impls (right)" },
    { "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix list (Trouble view)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble view)" },
    { "<leader>xt", "<cmd>Trouble todo toggle filter.buf=0<cr>", desc = "Todos (document)" },
    { "<leader>xT", "<cmd>Trouble todo toggle<cr>", desc = "Todos (workspace)" },
  },
}
