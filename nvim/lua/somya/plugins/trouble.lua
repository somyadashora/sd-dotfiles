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
      -- Symbols outline (<leader>xs), two fixes for SystemVerilog:
      -- 1. slang-server kinds: signals are Variable, parameters TypeParameter,
      --    instances Object, macros Constant — none in Trouble's default
      --    symbol-kind allowlist, so they were silently hidden (ports/modules/
      --    functions only). SV joins the ft escape list (like help/markdown):
      --    all kinds show for SV buffers; other languages keep the curated set.
      -- 2. The default row format appends {text:Comment}, but slang's symbol
      --    range covers just the name token, so the "text" was the name again
      --    plus the rest of the source line — every row echoed its name twice.
      --    Name + position is all the outline needs.
      symbols = {
        win = { position = "right", size = 0.25 },
        filter = {
          any = {
            ft = { "help", "markdown", "systemverilog", "verilog" },
            -- kind list inherits from the default config
          },
        },
        format = "{kind_icon} {symbol.name} {pos}",
      },
      -- The lsp mode (<leader>xr) lists defs/refs/impls with a code-line per
      -- entry, so the default sidebar width truncates almost everything —
      -- unlike symbols (<leader>xs), which is just names. Rows are squeezed to
      -- one line (no wrap; whitespace runs collapsed by formatters.text above).
      -- TEMPORARILY disabled: the default sections also include incoming/
      -- outgoing calls, but slang-server (<= 0.2.8) fills call-hierarchy items
      -- with (0,0) range/selectionRange, so Trouble renders line 1 of the file
      -- (a ///// banner) for every entry. Waiting on an upstream bugfix
      -- (hudson-trading/slang-server — "Call hierarchy items have (0,0)
      -- range/selectionRange and undeduplicated cone leaves"); once fixed,
      -- re-add "lsp_incoming_calls" / "lsp_outgoing_calls" below. Until then
      -- <leader>vd/vl cover cone tracing properly (lsp/lspconfig.lua).
      lsp = {
        win = { position = "right", size = 0.25 },
        sections = {
          "lsp_definitions",
          "lsp_references",
          "lsp_implementations",
          "lsp_type_definitions",
          "lsp_declarations",
        },
      },
      -- "Workspace" diagnostics (<leader>xw), scoped to the cwd.
      --
      -- Neovim's diagnostic store is BUFFER-scoped — vim.diagnostic.get() with
      -- no bufnr returns every diagnostic nvim currently holds, and Trouble's
      -- source is a straight union over that. Nothing walks the project. So the
      -- stock `diagnostics` mode lists files that merely have a buffer HANDLE,
      -- which includes files you never opened: publishDiagnostics for any URI
      -- makes nvim vim.uri_to_bufnr() it into existence, so slang elaborating a
      -- whole .f filelist (or a gd jump into ~/.local/share/nvim/lazy/…) fills
      -- the list with paths nowhere near the tree. Upstream ships a cwd filter
      -- for exactly this, but commented out (sources/diagnostics.lua).
      --
      -- getcwd() (not uv.cwd()) so tab-local dirs win — :TabProject and the
      -- notes tab both tcd, and there the tab's project IS the workspace.
      -- Caveat this filter can't fix: a file with no diagnostics loaded is
      -- still invisible. Coverage equals whatever the LSP has analyzed, not
      -- everything under the cwd. <leader>xW drops the filter.
      diagnostics_cwd = {
        mode = "diagnostics",
        filter = function(items)
          local cwd = vim.fs.normalize(vim.fn.getcwd())
          local prefix = cwd:gsub("/$", "") .. "/"
          return vim.tbl_filter(function(item)
            local file = item.filename and vim.fs.normalize(item.filename)
            return file ~= nil and file:sub(1, #prefix) == prefix
          end, items)
        end,
      },
    },
  },
  keys = {
    { "<leader>xw", "<cmd>Trouble diagnostics_cwd toggle<cr>", desc = "Diagnostics (workspace/cwd)" },
    { "<leader>xW", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (all buffers, unscoped)" },
    { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Diagnostics (document)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols outline (right)" },
    { "<leader>xr", "<cmd>Trouble lsp toggle focus=false<cr>", desc = "LSP defs/refs/impls (right)" },
    { "<leader>xq", "<cmd>Trouble quickfix toggle<cr>", desc = "Quickfix list (Trouble view)" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble view)" },
    { "<leader>xt", "<cmd>Trouble todo toggle filter.buf=0<cr>", desc = "Todos (document)" },
    { "<leader>xT", "<cmd>Trouble todo toggle<cr>", desc = "Todos (workspace)" },
  },
}
