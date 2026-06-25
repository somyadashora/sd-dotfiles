return {
  -- aerial.nvim: a symbol outline (modules, interfaces, functions, tasks, classes,
  -- structs, enums) for navigating large unstructured files by *structure* instead
  -- of scrolling. Complements the fuzzy finder (find any file) and Harpoon (pinned
  -- working set) with "jump around inside one big file by its skeleton".
  --
  -- backends = { "treesitter", "lsp" }: treesitter first, so the outline works
  -- immediately off the SV grammar even with NO language server attached (e.g. a
  -- fresh project root before slang's filelist is built). When a server IS up
  -- (verible or slang), its richer document symbols take over. Document symbols are
  -- per-file/parse-derived, so this works even before slang has an elaborated
  -- design — unlike cone tracing, it never needs the full filelist.
  --
  -- Two maps under the <leader>o ("+Outline") group, both conflict-free.
  "stevearc/aerial.nvim",
  cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" },
  keys = { "<leader>oo", "<leader>os", "[o", "]o" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- aerial's default kind set (everything except Namespace).
    local default_kinds = {
      "Class", "Constructor", "Enum", "Function",
      "Interface", "Module", "Method", "Struct",
    }
    -- SV adds "Namespace": generate blocks are captured by the bundled SV query
    -- as kind "Namespace", which the default filter hides. Widen it for SV only
    -- (via the per-filetype table form, "_" = fallback) so generate blocks show
    -- alongside the always/initial/final/fork blocks from our queries/ extension.
    local sv_kinds = vim.list_extend(vim.deepcopy(default_kinds), { "Namespace" })

    -- queries/systemverilog/aerial.scm names always blocks by their keyword
    -- (always_comb/always_ff/…). For a NAMED block (`always_comb begin : my_logic`)
    -- upgrade that to the begin-block label here. This is done in Lua, not as a
    -- second query pattern, because tree-sitter yields the shallow keyword match
    -- before the deep label match, so a label pattern always loses aerial's
    -- same-node dedup — order-independent only in Lua.
    local function sv_child(node, ntype) -- first NAMED child of a given type
      for c in node:iter_children() do
        if c:named() and c:type() == ntype then return c end
      end
    end
    local function sv_always_label(node, bufnr)
      -- always_construct → statement → statement_item → seq_block → simple_identifier
      local stmt = sv_child(node, "statement")
      local sitem = stmt and sv_child(stmt, "statement_item")
      local seq = sitem and sv_child(sitem, "seq_block")
      local id = seq and sv_child(seq, "simple_identifier")
      return id and vim.treesitter.get_node_text(id, bufnr) or nil
    end

    require("aerial").setup({
      backends = { "treesitter", "lsp" }, -- treesitter first → works without LSP
      filter_kind = {
        ["_"] = default_kinds,    -- all other filetypes: aerial's default
        systemverilog = sv_kinds, -- + Namespace so generate blocks appear
      },
      post_parse_symbol = function(bufnr, item, ctx)
        if ctx.lang == "systemverilog" then
          local node = (ctx.match.symbol or ctx.match.type or {}).node
          if node and node:type() == "always_construct" then
            local label = sv_always_label(node, bufnr)
            if label then item.name = label end
          end
        end
        return true
      end,
      layout = {
        default_direction = "right", -- outline on the right, like a minimap
        min_width = 28,
      },
      show_guides = true, -- tree guide lines for nested scopes
    })

    -- Toggle the outline sidebar (focuses it; <CR> jumps, j/k navigate).
    vim.keymap.set("n", "<leader>oo", "<cmd>AerialToggle<cr>",
      { desc = "Toggle outline (aerial)" })

    -- Fuzzy-jump to any symbol via Telescope (extension ships inside aerial.nvim;
    -- load it lazily here so telescope only loads when actually used).
    vim.keymap.set("n", "<leader>os", function()
      require("telescope").load_extension("aerial")
      vim.cmd("Telescope aerial")
    end, { desc = "Outline symbols (Telescope)" })

    -- Jump the cursor through symbols (works in the code buffer, outline open or
    -- not). ]o next, [o prev — mirrors the ]q/[q quickfix bracket idiom.
    vim.keymap.set("n", "]o", function() require("aerial").next() end,
      { desc = "Next outline symbol (aerial)" })
    vim.keymap.set("n", "[o", function() require("aerial").prev() end,
      { desc = "Prev outline symbol (aerial)" })
  end,
}
