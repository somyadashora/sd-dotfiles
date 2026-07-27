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
      -- SEVEN classes, not ten. SPEC folded into NOTE (both are "here is why /
      -- here is where it is written", neither asks you to do anything), and
      -- WARN + TEST folded into REVIEW (all three mean "a human has to look at
      -- this before you trust it"). Fewer classes is the point: the palette
      -- below has to stay clear of the syntax colours AND of itself, and every
      -- class removed is elbow room for the ones that are left.
      --
      -- merge_keywords = false makes this table REPLACE the plugin's defaults
      -- instead of merging with them. Without it the defaults keep WARN, TEST
      -- and NOTE alive as canonical keywords of their own, so a word listed as
      -- an alias here would map to two different classes depending on table
      -- iteration order — the colour would change between sessions.
      merge_keywords = false,
      keywords = {
        FIX    = { icon = " ", color = "bug",  alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        HACK   = { icon = " ", color = "hack" },
        PERF   = { icon = " ", color = "perf", alt = { "IMPORTANT", "OPTIM", "OPTIMIZE", "PERFORMANCE" } },
        REVIEW = { icon = " ", color = "review", alt = { "WARN", "WARNING", "XXX", "TEST", "TESTING", "PASSED", "FAILED" } },
        TODO   = { icon = " ", color = "todo" },
        FUTURE = { icon = "󰥔 ", color = "future" },
        NOTE   = { icon = " ", color = "note", alt = { "INFO", "SPEC" } },
      },
      -- Only CUSTOM colours need listing; the built-ins (error/warning/info/
      -- hint/default/test) are merged in by the plugin. Each entry is a
      -- fallback chain: hl group names first, then a literal hex — literal
      -- here so the categories stay stable when styler swaps colorschemes per
      -- filetype (todo's highlight groups are global, not per-window).
      --
      -- Reusing the SV scheme's accent slots is the obvious move and the wrong
      -- one: those slots are exactly what the code already wears. Measured in a
      -- .sv buffer, the vivid versions collided outright —
      --
      --   #f38ba8  Macro, Define, Keyword, Operator
      --   #fab387  @variable.parameter
      --   #f9e2af  PreProc, String
      --   #89dceb  @type
      --   #a6e3a1  Function
      --   #cba6f7  Constant, Number, @constant.macro  (also the repo accent)
      --
      -- so a todo read as just another identifier. Note those syntax colours
      -- are THEMSELVES pastels (the scheme is Catppuccin), which is the whole
      -- difficulty: go pale and you converge on them, go dark and green/orange
      -- turn muddy (olive, brown) where blues and violets still read clean.
      -- Pastel teal for NOTE, for instance, lands 0.13 from Function.
      --
      -- So every class sits at moderate saturation and mid-high lightness —
      -- roughly S .30-.44, L .60-.72 — which is far enough from the syntax to
      -- be a different thing (min RGB distance 0.20, was 0.00) and near enough
      -- to Comment (#7f849c) to sit back in the text. Pill contrast stays
      -- 5.1-10.3; the plugin picks badge foreground with maximize_contrast
      -- against Normal, so it can't become unreadable.
      colors = {
        bug    = { "#c66c6f" }, -- rose    — broken, must fix
        hack   = { "#bb9c81" }, -- tan     — works, but wrong: workaround/smell
        perf   = { "#cec1a1" }, -- sand    — timing / area / throughput
        review = { "#bf7dad" }, -- plum    — a human must check: warn/verify/review
        todo   = { "#7eb7c8" }, -- slate   — queued work
        future = { "#9287c9" }, -- dusk    — deferred by choice, next revision
        note   = { "#7dbf7d" }, -- green   — reference + explanation, no action
      },
    })

    local keymap = vim.keymap

    -- ]t / [t jump AND report position: "TODO 3 of 4", coloured by the
    -- keyword — the same counter ]d and ]h give (see core/navmsg.lua).
    --
    -- todo-comments has no list API for a buffer (its pickers shell out to
    -- ripgrep, which answers a workspace question, not "where am I in THIS
    -- file"), so the buffer is scanned with the plugin's own matcher and the
    -- same comments_only rule its jump applies — that reproduces exactly the
    -- list jump_next walks, keeping the count honest.
    local navmsg = require("somya.core.navmsg")
    local function todos_in_buf(buf)
      local hl = require("todo-comments.highlight")
      local cfg = require("todo-comments.config")
      -- Resolve 0 to the real buffer number: is_comment looks the buffer up in
      -- vim.treesitter.highlighter.active[buf], which is keyed by actual bufnr,
      -- so a 0 here silently reports "not a comment" for every line and the
      -- list comes back empty.
      if buf == 0 then buf = vim.api.nvim_get_current_buf() end
      local out = {}
      for l, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        local ok, start, _, kw = pcall(hl.match, line)
        if ok and start and kw then
          if cfg.options.highlight.comments_only
            and hl.is_comment(buf, l - 1, start) == false then
            kw = nil
          end
          if kw then
            -- Resolve aliases (WARNING -> REVIEW, INFO -> NOTE, ...) so the
            -- label and its highlight group match the configured keyword.
            out[#out + 1] = { lnum = l, kw = cfg.keywords[kw] or kw }
          end
        end
      end
      return out
    end

    local function todo_jump(forward)
      return function()
        local before = vim.api.nvim_win_get_cursor(0)[1]
        local tc = require("todo-comments")
        for _ = 1, vim.v.count1 do
          if forward then tc.jump_next() else tc.jump_prev() end
        end
        local line = vim.api.nvim_win_get_cursor(0)[1]
        -- jump_next/prev don't wrap: on the last todo the cursor doesn't move
        -- and the plugin has already warned. Don't announce a stale position.
        if line == before then return end
        local todos = todos_in_buf(0)
        for i, t in ipairs(todos) do
          if t.lnum == line then
            navmsg.echo(t.kw, i, #todos, "TodoFg" .. t.kw)
            return
          end
        end
      end
    end

    keymap.set("n", "]t", todo_jump(true), { desc = "Next todo comment" })
    keymap.set("n", "[t", todo_jump(false), { desc = "Previous todo comment" })
  end,
}
