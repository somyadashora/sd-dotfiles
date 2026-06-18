return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
    -- mason is lazy (cmd-only); pull it in here so mason-lspconfig's
    -- automatic_enable runs before this server config on BufReadPre.
    "williamboman/mason.nvim",
  },
  config = function()
    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        -- SLANG related keymaps
        opts.desc = "Slang trace signal drivers"
        keymap.set("n", "<leader>Sd", function()
          vim.lsp.buf.incoming_calls()
        end, opts)

        opts.desc = "Slang trace signal loads"
        keymap.set("n", "<leader>Sl", function()
          vim.lsp.buf.outgoing_calls()
        end, opts)

        opts.desc = "Open quickfix list"
        keymap.set("n", "<leader>Sq", "<cmd>copen<CR>", opts)

        opts.desc = "Show active LSP clients"
        keymap.set("n", "<leader>Si", function()
          local clients = vim.lsp.get_clients({ bufnr = ev.buf })
          if #clients == 0 then
            print("No active LSP clients for this buffer")
            return
          end

          for _, client in ipairs(clients) do
            print(client.name .. " root=" .. (client.config.root_dir or "nil"))
          end
        end, opts)



        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>Rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    capabilities.textDocument.foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    }
    vim.lsp.config("*", {
      capabilities = capabilities,
    })

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    -- nvim-lspconfig 0.11+: use vim.lsp.config() API instead of deprecated require('lspconfig') framework
    -- automatic_enable in mason.lua will handle default setup for installed servers

    -- configure verible server with custom settings
    -- PROJECT SETUP: run `verible-init` at the project root to generate:
    --   verible.filelist     line-by-line list of .sv/.svh/.v -> project-wide
    --                        go-to-def / references / hover (verible has no
    --                        +incdir+, so headers MUST be listed here too)
    --   .rules.verible_lint  optional lint rules (+enable / -disable); found
    --                        via --rules_config_search up the dir tree
    -- root_markers below let the LS locate the project root (where the filelist
    -- lives); without it verible falls back to single-file mode.
    vim.lsp.config("verible", {
      capabilities = capabilities,
      cmd = { "verible-verilog-ls", "--rules_config_search" },
      filetypes = { "verilog", "systemverilog" },
      root_markers = { "verible.filelist", ".rules.verible_lint", ".git" },
    })

    -- configure slang-server for system verilog
    vim.lsp.config("slang-server", {
        capabilities = capabilities,
        cmd = { vim.fn.expand("~/.local/bin/slang-server") },
        root_markers = { ".slang", ".git" },
        filetypes = { "systemverilog", "verilog" },
      })

local function stop_lsp_by_name(name)
    for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
      client:stop()
    end
  end

  vim.api.nvim_create_user_command("UseVerible", function()
    vim.lsp.enable("slang-server", false)
    stop_lsp_by_name("slang-server")

    vim.lsp.enable("verible", true)
    vim.cmd("edit")
  end, {})

  vim.api.nvim_create_user_command("UseSlang", function()
    vim.lsp.enable("verible", false)
    stop_lsp_by_name("verible")

    vim.lsp.enable("slang-server", true)
    vim.cmd("edit")
  end, {})


    -- configure lua server with special settings
    vim.lsp.config("lua_ls", {
      capabilities = capabilities,
      cmd = { "lua-language-server" },
      settings = {
        Lua = {
          -- make the language server recognize "vim" global
          diagnostics = {
            globals = { "vim" },
          },
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    })
    if vim.fn.executable("lua-language-server") == 1 then
      vim.lsp.enable("lua_ls")
    end
  end,
}
