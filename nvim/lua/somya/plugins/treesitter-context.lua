return {
  -- A sticky header (winbar-like, pinned to the top of the window) showing the
  -- enclosing scope as you scroll: `module ... → always_ff → if (...)`. In a long
  -- unstructured SystemVerilog file you never lose track of which block the code
  -- on screen belongs to. Pure treesitter (no LSP), so it also works for tcl,
  -- bash, make, python, etc. Pairs naturally with the folding (ufo) already set up.
  --
  -- One keybinding: <leader>ut toggles it (under the +UI/Theme group). The header
  -- itself is passive — it just renders as you move, no keys needed for the core
  -- value. To jump up to the enclosing scope on demand, the plugin also exposes
  -- require("treesitter-context").go_to_context() if you want to bind it later.
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    -- Headroom so a full always -> (if ->) case -> case-item stack all shows at
    -- once without being trimmed. The case levels come from our query extension
    -- at nvim/queries/systemverilog/context.scm (the bundled SV query omits case).
    max_lines = 6,          -- cap the sticky header height (deeply nested blocks)
    multiline_threshold = 1, -- collapse multi-line scope openers to one line
    trim_scope = "outer",    -- if still over max_lines, drop the outermost first
    mode = "cursor",         -- context follows the cursor, not just the top line
  },
  config = function(_, opts)
    local tsc = require("treesitter-context")
    tsc.setup(opts)
    vim.keymap.set("n", "<leader>ut", tsc.toggle,
      { desc = "Toggle treesitter context (sticky scope header)" })
  end,
}
