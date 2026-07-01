return {
  -- In-buffer rendering for Markdown: headings become colored pills, bullets get
  -- real glyphs, code blocks get a background, tables are aligned, checkboxes and
  -- callouts render, etc. — all as virtual text, so the underlying file is never
  -- touched. Pairs with the treesitter markdown/markdown_inline parsers already
  -- installed. Handy for the telekasten vault (~/.somyadashora/sd-notes) and any
  -- README/spec you open. It intentionally un-renders the line the cursor is on
  -- so you always see the raw source where you're editing.
  --
  -- One keybinding: <leader>um toggles rendering (under the +UI/Theme group). It
  -- starts ON (enabled = true) for every markdown buffer.
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    enabled = true, -- render on by default; <leader>um toggles
  },
  config = function(_, opts)
    local rm = require("render-markdown")
    rm.setup(opts)
    vim.keymap.set("n", "<leader>um", rm.toggle,
      { desc = "Toggle markdown rendering (render-markdown)" })
  end,
}
