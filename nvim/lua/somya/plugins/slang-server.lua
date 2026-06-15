-- slang-server.nvim  (hudson-trading/slang-server)
-- SystemVerilog LSP. Activate with :UseSlang (see plugins/lsp/lspconfig.lua).
--
-- ============================================================================
-- PROJECT SETUP REQUIREMENTS  (do this once per repo, e.g. in your rtl project)
-- ============================================================================
-- The server's root is detected by a `.slang` marker (see root_markers in
-- lspconfig.lua). slang-server uses a `.slang/` DIRECTORY containing config,
-- NOT a bare `.slang` file. Without it the server starts but indexes nothing.
--
-- You need TWO things at the project root:
--
--   1. .slang/server.json   -- workspace config (commit this)
--   2. a filelist (.f file)  -- the actual list of sources + flags
--
-- ---------------------------------------------------------------------------
-- 1) .slang/server.json   (minimal config for a repo that only has rtl/)
-- ---------------------------------------------------------------------------
--   {
--     "flags": "-f rtl.f",          // pass our filelist to slang
--     "index": [                     // dirs slang-server scans for symbols
--       { "dirs": ["rtl"] }
--     ]
--   }
--
--   Config is hierarchical (later overrides scalars, lists append):
--     .slang/server.json         team-shared, in source control
--     ~/.slang/server.json       personal defaults across all projects
--     .slang/local/server.json   personal overrides -> add to .gitignore
--
-- ---------------------------------------------------------------------------
-- 2) rtl.f   (slang flag/filelist -- one flag or file per line)
-- ---------------------------------------------------------------------------
--   -I rtl                 // include dir for `include "...".svh files
--   --top my_top           // optional: set top module to resolve elaboration
--   -D SYNTHESIS           // optional: defines, -D NAME or -D NAME=VALUE
--   rtl/foo.sv             // source files (compile units)
--   rtl/bar.sv
--   ...
--
-- ============================================================================
-- QUICK SETUP:  run `slang-init` (nvim/scripts/slang-init) at the project root
-- ============================================================================
-- It creates .slang/, generates .slang/<dir>.f + .slang/server.json, and adds
-- .slang/local/ to .gitignore -- everything below, automated:
--
--   slang-init                  # scans ./rtl
--   slang-init -d src -t my_top # scan ./src, set top module
--   slang-init --regen-only     # just rebuild the .f after adding files
--
-- The manual steps below explain what it produces.
--
-- ============================================================================
-- GENERATING rtl.f FROM A BARE rtl/ FOLDER (manual equivalent)
-- ============================================================================
-- You only have an rtl/ folder of SystemVerilog files -> build the filelist:
--
--   # list all .sv/.v sources, add rtl/ as an include path for .svh headers
--   { echo "-I rtl"; \
--     find rtl -type f \( -name '*.sv' -o -name '*.v' \) | sort; } > rtl.f
--
-- If headers (.svh) live in subdirs, add an -I for each:
--
--   { find rtl -type f -name '*.svh' -exec dirname {} \; | sort -u \
--       | sed 's/^/-I /'; \
--     find rtl -type f \( -name '*.sv' -o -name '*.v' \) | sort; } > rtl.f
--
-- Note: list .sv/.v as sources; do NOT list .svh files -- they are pulled in
-- via `include from the -I dirs.
--
-- Then create the config dir:
--
--   mkdir -p .slang
--   # write .slang/server.json as shown above
--   echo ".slang/local/" >> .gitignore
--
-- Reload nvim (or :UseSlang), open a file under rtl/, then verify with:
--   :checkhealth vim.lsp        -- confirm slang-server attached
--   :LspLog                     -- inspect server log on errors
-- ============================================================================

return {
    {
      "hudson-trading/slang-server.nvim",
      dependencies = {
        "MunifTanjim/nui.nvim",
      },
      opts = {},
    },
  }
