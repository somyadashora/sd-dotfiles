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

        -- Generic LSP actions live under <leader>v ("LSP / Code"). These work
        -- with ANY attached server (verible, slang-server, lua_ls) — they are not
        -- server-specific. Server-specific maps are guarded by client name below.
        opts.desc = "LSP: code action"
        keymap.set({ "n", "v" }, "<leader>va", vim.lsp.buf.code_action, opts) -- in visual mode applies to selection

        opts.desc = "LSP: smart rename"
        keymap.set("n", "<leader>vr", vim.lsp.buf.rename, opts)

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

        opts.desc = "LSP: info (active clients)"
        keymap.set("n", "<leader>vi", function()
          local clients = vim.lsp.get_clients({ bufnr = ev.buf })
          if #clients == 0 then
            print("No active LSP clients for this buffer")
            return
          end

          for _, client in ipairs(clients) do
            print(client.name .. " root=" .. (client.config.root_dir or "nil"))
          end
        end, opts)

        opts.desc = "LSP: restart"
        keymap.set("n", "<leader>vR", "<cmd>LspRestart<CR>", opts)

        -- Server-specific keymaps. slang-server supports LSP call-hierarchy, which
        -- we use for signal cone tracing; verible does not, so these only attach
        -- when slang-server is the client. Switching with :UseVerible / :UseSlang
        -- re-attaches the buffer, so these maps appear/disappear accordingly.
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.name == "slang-server" then
          -- Cone traces render in Trouble (previewable tree, auto-refresh)
          -- instead of the raw quickfix list vim.lsp.buf.*_calls() would open.
          opts.desc = "Slang: trace signal drivers"
          keymap.set("n", "<leader>vd", "<cmd>Trouble lsp_incoming_calls<CR>", opts)

          opts.desc = "Slang: trace signal loads"
          keymap.set("n", "<leader>vl", "<cmd>Trouble lsp_outgoing_calls<CR>", opts)
        end
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

    -- Both SystemVerilog servers are INACTIVE by default. :UseVerible / :UseSlang
    -- turn one on (and the other off). Disabling them explicitly here encodes the
    -- intent in code instead of relying solely on mason-lspconfig's automatic_enable
    -- exclude list (verible is a mason package, so without this it could be
    -- auto-enabled if that exclude entry ever changed).
    vim.lsp.enable("verible", false)
    vim.lsp.enable("slang-server", false)

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

  -- Back to the startup state: no SystemVerilog LSP at all.
  vim.api.nvim_create_user_command("UseNoSvLsp", function()
    for _, name in ipairs({ "verible", "slang-server" }) do
      vim.lsp.enable(name, false)
      stop_lsp_by_name(name)
    end
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
