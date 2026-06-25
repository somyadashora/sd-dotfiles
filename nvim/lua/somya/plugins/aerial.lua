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
  keys = { "<leader>oo", "<leader>os" },
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

    require("aerial").setup({
      backends = { "treesitter", "lsp" }, -- treesitter first → works without LSP
      filter_kind = {
        ["_"] = default_kinds,    -- all other filetypes: aerial's default
        systemverilog = sv_kinds, -- + Namespace so generate blocks appear
      },
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
  end,
}
