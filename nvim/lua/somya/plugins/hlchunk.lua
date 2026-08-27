-- hlchunk.nvim — draw a bracket around the block the cursor is in
--
--   ╭─ always_ff @(posedge clk or negedge rst_n) begin
--   │    if (!rst_n) begin
--   │      q <= '0;
--   │    end
--   ╰─ end
--
-- The "C" that wraps the enclosing chunk. Where indent-blankline draws a guide
-- for EVERY indent level and mini.indentscope draws a line for the one you're
-- in, this closes the shape: a corner at the opening line, a rule down the
-- side, a corner at the closing line — so `end` / `endmodule` is visibly
-- paired with what opened it. On by default; <leader>uk / :ChunkToggle flips it.
--
-- ── Only the `chunk` module is used ──────────────────────────────────────────
-- hlchunk ships four modules (chunk / indent / line_num / blank). Only `chunk`
-- is enabled: indent guides already belong to indent-blankline, and running two
-- guide renderers over the same columns is how you end up with doubled glyphs.
-- Same "one concept, one owner" rule that keeps bookmarks.nvim and marks.nvim
-- from overlapping.
--
-- ── The handoff with mini.indentscope ────────────────────────────────────────
-- Both answer "what block am I in", at different columns, and drawing both at
-- once is three vertical lines of clutter next to indent-blankline's guides. So
-- the toggle SWAPS them rather than leaving you with nothing: chunk on ⇒
-- indentscope's symbol off, chunk off ⇒ indentscope's symbol back. Only its
-- DRAWING is suppressed (`vim.g.miniindentscope_disable`, which mini checks in
-- `auto_draw` alone) — `[i` / `]i` / `ii` / `ai` keep working in both states,
-- since operator/textobject never consult the flag. The scope colour is shared
-- for the same reason: whichever renderer is up, "current scope" is lavender.
--
-- ── SystemVerilog had to be taught ───────────────────────────────────────────
-- hlchunk picks the chunk off the treesitter tree, matching node types against
-- a per-filetype table, or — with no table for the filetype — a list of regexes
-- written for curly-brace languages (`^func`, `^if`, `class`, `for`, …). Almost
-- none of that matches the gmlarumbe SV grammar: `module_declaration`,
-- `seq_block`, `always_construct`, `conditional_statement` and `case_statement`
-- all miss, which would leave the repo's primary language with nearly no chunks
-- at all. So we register a real `systemverilog` table below. Note the semantics
-- flip once a filetype has a table: it is matched by EXACT node type, with no
-- regex fallback — a construct missing from the list simply gets no bracket.
-- Node names are from the pinned grammar's `src/node-types.json`
-- (gmlarumbe/tree-sitter-systemverilog, the revision nvim-treesitter installs).
-- Adding another language is the same move: `ts_node_type.<ft> = { ... }`.
--
-- ── Graceful degradation ─────────────────────────────────────────────────────
-- `use_treesitter = true` is not optional in practice: hlchunk's non-treesitter
-- path is `searchpair("{", "", "}")`, which knows braces and nothing else — it
-- cannot see `begin`/`end`, `module`/`endmodule`, or a Python block. On a host
-- where treesitter parsers can't be built (treesitter.lua turns itself off
-- there), hlchunk finds no parser and silently draws nothing; `notify = false`
-- keeps that from becoming a message on every buffer. Nothing else changes.

return {
  "shellRaining/hlchunk.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- ── Teach the SV grammar's node types ────────────────────────────────────
    -- Injected into hlchunk's own lookup table (a plain module table, so the
    -- assignment is visible to every later `is_suit_type` call). Deliberately
    -- excluded: `statement` / `statement_item` / `module_item` / `case_item`,
    -- which are wrappers — bracketing them would hide the `case` or `always`
    -- they sit inside, since hlchunk stops at the INNERMOST matching node.
    local sv_nodes = {
      -- design containers
      module_declaration          = true,
      interface_declaration       = true,
      program_declaration         = true,
      package_declaration         = true,
      checker_declaration         = true,
      config_declaration          = true,
      udp_declaration             = true,
      -- classes
      class_declaration           = true,
      interface_class_declaration = true,
      class_constructor_declaration = true,
      -- subprograms
      function_declaration        = true,
      function_body_declaration   = true,
      task_declaration            = true,
      task_body_declaration       = true,
      -- procedural blocks
      always_construct            = true,
      initial_construct           = true,
      final_construct             = true,
      seq_block                   = true, -- begin … end
      par_block                   = true, -- fork  … join
      -- control flow
      conditional_statement       = true, -- if / else if / else
      case_statement              = true,
      loop_statement              = true, -- for / foreach / while / repeat / forever
      randcase_statement          = true,
      randsequence_statement      = true,
      -- generate
      generate_region             = true,
      generate_block              = true,
      loop_generate_construct     = true,
      if_generate_construct       = true,
      case_generate_construct     = true,
      conditional_generate_construct = true,
      -- verification
      constraint_declaration      = true,
      constraint_block            = true,
      covergroup_declaration      = true,
      cross_body                  = true,
      combinational_body          = true,
      sequential_body             = true,
      property_declaration        = true,
      sequence_declaration        = true,
      clocking_declaration        = true,
      modport_declaration         = true,
      specify_block               = true,
      -- types and ports
      type_declaration            = true, -- typedef struct/union/enum { … }
      list_of_port_declarations   = true, -- the ANSI port list in ( … )
    }

    -- Registered under BOTH filetypes: `.sv`/`.svh` land on `systemverilog` and
    -- `.v` on `verilog`, and one grammar serves both (treesitter.lua), so `.v`
    -- would otherwise drop back to the brace-language regexes.
    local ts_node_type = require("hlchunk.utils.ts_node_type")
    ts_node_type.systemverilog = sv_nodes
    ts_node_type.verilog = sv_nodes

    -- ── Filetypes ────────────────────────────────────────────────────────────
    -- hlchunk's own exclude list already covers the panels this config opens
    -- (alpha, NvimTree, aerial, trouble, toggleterm, lazy, mason, qf, help,
    -- TelescopePrompt, DressingInput, …). Added here: the panels it can't know
    -- about, plus `markdown` — render-markdown.nvim already paints that buffer
    -- with its own overlay virtual text at the same columns, and "chunk" isn't
    -- a thing you're looking for in prose anyway.
    local exclude = vim.tbl_extend("force", require("hlchunk.utils.filetype").exclude_filetypes, {
      BookmarksTree = true,
      neominimap    = true,
      calendar      = true, -- telekasten's calendar-vim pane
      markdown      = true,
    })

    -- ── The chunk module ─────────────────────────────────────────────────────
    -- Built directly instead of through `hlchunk.setup()` (which is the same
    -- `require` + construct, minus the handle) so the toggle can read
    -- `conf.enable` as the real state — `:EnableHLChunk` / `:DisableHLChunk`,
    -- if typed by hand, flip the same field, so nothing can drift out of sync.
    local chunk = require("hlchunk.mods.chunk")({
      enable = true,
      priority = 15,
      use_treesitter = true,
      straight = false, -- corners + arms; `true` would give a bare vertical rule
      notify = false,   -- see "Graceful degradation" above

      -- Instant, no animation — same call as indentscope's `gen_animation.none()`.
      -- `delay = 0` is what selects hlchunk's immediate path over its animated
      -- one; redundant redraws are already skipped by its own diff check.
      delay = 0,
      duration = 0,

      -- Chunk brackets are cheap, but the treesitter walk behind them isn't:
      -- past this size hlchunk disables itself for the SESSION (not just that
      -- buffer) on BufWinEnter, silently (see `notify`). If a generated netlist
      -- ever trips it, <leader>uk turns it back on.
      max_file_size = 2 * 1024 * 1024,

      -- A tier-2 grammar's idea of a parse error is not authoritative here —
      -- UVM macro soup parses badly and is perfectly legal, and slang/verible
      -- already report real syntax errors as diagnostics, in the repo's red.
      -- A second, less reliable opinion painting the bracket red is noise, so
      -- the error styling is configured (HLChunk2, below) but not armed.
      error_sign = false,

      chars = {
        left_top       = "╭",
        left_bottom    = "╰",
        horizontal_line = "─",
        vertical_line  = "│",
        left_arrow     = "─",
        right_arrow    = "─", -- default is ">"; a plain rule keeps the "C" clean
      },

      -- HLChunk1 normal / HLChunk2 error. Lavender #b4befe is deliberately the
      -- same catppuccin colour mini.indentscope uses for its symbol — the two
      -- take turns drawing the same idea, so they read as one indicator with
      -- two shapes. Red #ff6188 is the repo's Monokai diagnostic red, kept in
      -- step with `error_sign` should it ever be turned on. hlchunk re-applies
      -- both on ColorScheme itself, so styler's per-filetype scheme reloads
      -- don't need the usual autocmd here.
      style = {
        { fg = "#b4befe" },
        { fg = "#ff6188" },
      },

      -- `ic` = inner chunk (visual + operator-pending): `vic` selects the block,
      -- `dic` deletes it. Free key — mini.indentscope owns `ii`/`ai`, and vim
      -- has no builtin `ic`. The indent pair and the chunk pair disagree on
      -- purpose: `ii` is what's indented, `ic` is what treesitter calls a block.
      textobject = "ic",

      exclude_filetypes = exclude,
    })

    -- ── On by default, and the swap ──────────────────────────────────────────
    local function apply(on)
      if on then
        chunk:enable()
      else
        chunk:disable()
      end
      -- Hand the "current scope" job to whichever renderer is up. mini reads
      -- this flag in `auto_draw` only, so its motions and text objects survive
      -- both states; the explicit draw/undraw is just so the swap lands now
      -- instead of on the next CursorMoved. (Guarded: at startup mini may not
      -- have loaded yet, and the flag alone is enough for it when it does.)
      vim.g.miniindentscope_disable = on
      if _G.MiniIndentscope then
        if on then
          _G.MiniIndentscope.undraw()
        else
          _G.MiniIndentscope.draw()
        end
      end
    end

    apply(true)

    local function toggle()
      local on = not chunk.conf.enable
      apply(on)
      vim.notify("chunk highlight " .. (on and "on" or "off — indent scope line back"))
    end

    vim.api.nvim_create_user_command("ChunkToggle", toggle, {
      desc = "Toggle the chunk bracket (swaps with the indent scope line)",
    })
    vim.keymap.set("n", "<leader>uk", toggle, { desc = "Toggle chunk bracket" })
  end,
}
