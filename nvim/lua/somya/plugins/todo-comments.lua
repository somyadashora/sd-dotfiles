return {
  "folke/todo-comments.nvim",
  -- Highlights need to be active when a file opens; defer to first buffer read
  -- rather than startup. (Also loads as a telescope/trouble dependency.)
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("todo-comments").setup({
      -- A keyword only counts as a todo when it sits right after a comment
      -- leader (`//` SV/C, `#` bash, `--` lua, `/*` block) and is terminated by
      -- a colon, a space, or end-of-line. So `// FIX`, `// FIX:`, `# TODO:` and
      -- `# TODO` match, but the bare word "SPEC" in prose (or the "spec" prefix
      -- of "specifications") does NOT.
      --
      -- The highlight pattern is the single source of truth: Trouble/Telescope/
      -- quickfix (`<leader>xt`/`xT`) run ripgrep to gather candidate lines, then
      -- re-filter every line through it (todo-comments search.lua). `comments_only`
      -- below only guards in-buffer highlighting, not that list — so the comment
      -- leader requirement has to live in the pattern itself.
      highlight = {
        -- vim very-magic regex. `%(...)` is non-capturing; the first capturing
        -- group must be exactly the keyword (the plugin uses it for positioning).
        pattern = [[.*%(//|#|--|/\*)\s*(KEYWORDS)%(:|\s|$)]],
        -- "wide" (default) draws one char past the keyword (finish+1), which
        -- overflows 'end_col' when a colon-less keyword sits at end-of-line
        -- (e.g. `-- TODO`). "bg" highlights just the keyword, no overflow.
        keyword = "bg",
      },
      search = {
        -- ripgrep (Rust) regex — only gathers candidate lines; the highlight
        -- pattern above does the real filtering. Mirror the leader + terminator
        -- rule so rg doesn't drag in every prose mention.
        pattern = [[(?://|#|--|/\*)\s*(KEYWORDS)(?::|\s|$)]],
      },
      keywords = {
        FIXME = {
          color = "error",
          alt = { "FIX" },
          icon = " ",
        },
        TODO = { icon = " ", color = "info" },
        REVIEW = { icon = " ", color = "warning", alt = { "WARNING" } },
        PERF = { icon = " ", alt = { "IMPORTANT" } },
        SPEC = { icon = "󰦨 " },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
    })

    local keymap = vim.keymap
    keymap.set("n", "]t", function()
      require("todo-comments").jump_next()
    end, { desc = "Next todo comment" })
    keymap.set("n", "[t", function()
      require("todo-comments").jump_prev()
    end, { desc = "Previous todo comment" })
  end,
}
