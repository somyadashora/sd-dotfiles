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

        -- Hover float styling, shared by both K mappings below. The border +
        -- the NormalFloat/FloatBorder overrides in core/theme.lua make the box
        -- read as a panel floating above the code. Press K a SECOND time to
        -- jump INTO the float (normal buffer: yank/search/visual all work),
        -- q closes it from inside (moving the cursor outside also closes it).
        local hover_cfg = { border = "rounded", max_width = 100, max_height = 30 }

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", function()
          vim.lsp.buf.hover(hover_cfg)
        end, opts) -- show documentation for what is under cursor

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
          -- Cone traces go through a custom request, not Trouble's own
          -- lsp_incoming_calls source. slang-server (0.2.x) returns call items
          -- with only name+uri — range/selectionRange default to (0,0) — and one
          -- entry per cone LEAF with no dedup. Trouble labels each call with the
          -- text at the caller item's range, i.e. line 1 of the driving file
          -- (usually a ///// banner), repeated per leaf. So: request the cone
          -- ourselves, dedup by location, label entries with the hierarchical
          -- signal path slang puts in `name`, and render via Trouble's qflist.
          local function slang_cone(incoming)
            return function()
              local cl = vim.lsp.get_clients({ bufnr = 0, name = "slang-server" })[1]
              if not cl then return end
              local pos = vim.lsp.util.make_position_params(0, cl.offset_encoding)
              cl:request("textDocument/prepareCallHierarchy", pos, function(perr, prep)
                if perr or not prep or #prep == 0 then
                  vim.notify("Slang: nothing to trace under cursor", vim.log.levels.WARN)
                  return
                end
                local method = incoming and "callHierarchy/incomingCalls"
                                         or "callHierarchy/outgoingCalls"
                cl:request(method, { item = prep[1] }, function(cerr, calls)
                  if cerr or not calls or #calls == 0 then
                    vim.notify("Slang: no " .. (incoming and "drivers" or "loads")
                      .. " found for " .. prep[1].name, vim.log.levels.WARN)
                    return
                  end
                  local seen, qf = {}, {}
                  for _, call in ipairs(calls) do
                    local item = call.from or call.to
                    local r = (call.fromRanges and call.fromRanges[1]) or item.range
                    local fname = vim.uri_to_fname(item.uri)
                    local key = table.concat(
                      { fname, r.start.line, r.start.character, item.name }, ":")
                    if not seen[key] then
                      seen[key] = true
                      qf[#qf + 1] = {
                        filename = fname,
                        lnum = r.start.line + 1,
                        col = r.start.character + 1,
                        text = item.name,
                      }
                    end
                  end
                  vim.fn.setqflist({}, " ", {
                    title = (incoming and "Drivers of " or "Loads of ") .. prep[1].name,
                    items = qf,
                  })
                  vim.cmd("Trouble qflist open")
                end)
              end)
            end
          end

          opts.desc = "Slang: trace signal drivers"
          keymap.set("n", "<leader>vd", slang_cone(true), opts)

          opts.desc = "Slang: trace signal loads"
          keymap.set("n", "<leader>vl", slang_cone(false), opts)

          -- Macro-aware hover. slang-server's macro hover works and includes
          -- the expansion ("Expands to <value>"), but two things make stock K
          -- useless on macros: hovering the leading backtick of `NAME returns
          -- nothing (only the name token resolves), and the hover buries the
          -- definition + expansion below the ENTIRE comment block preceding
          -- the `define (harvested as doc comment — banners included). This
          -- buffer-local K nudges the position off a backtick and, for macro
          -- (DefineDirective) hovers only, keeps just the header and code
          -- sections. Non-macro hovers pass through untouched; any surprise
          -- falls back to stock vim.lsp.buf.hover.
          opts.desc = "Hover (slang macro-aware)"
          keymap.set("n", "K", function()
            local scl = vim.lsp.get_clients({ bufnr = 0, name = "slang-server" })[1]
            if not scl then return vim.lsp.buf.hover(hover_cfg) end
            local params = vim.lsp.util.make_position_params(0, scl.offset_encoding)
            local col = params.position.character
            if vim.api.nvim_get_current_line():sub(col + 1, col + 1) == "`" then
              params.position.character = col + 1
            end
            scl:request("textDocument/hover", params, function(err, res)
              if err or not res or not res.contents then
                return vim.lsp.buf.hover(hover_cfg)
              end
              local md = type(res.contents) == "table" and res.contents.value
                or res.contents
              if type(md) ~= "string" then return vim.lsp.buf.hover(hover_cfg) end
              if md:match("^DefineDirective") then
                local sections = vim.split(md, "\n+%-%-%-\n+")
                local keep = { sections[1] }
                for i = 2, #sections do
                  if sections[i]:find("```") then keep[#keep + 1] = sections[i] end
                end
                md = table.concat(keep, "\n\n---\n\n")
              end
              -- focus_id makes a repeat K (same buffer) FOCUS the open float
              -- instead of redrawing it — the same double-K behavior stock
              -- vim.lsp.buf.hover has — so its contents can be yanked.
              vim.lsp.util.open_floating_preview(
                vim.split(md, "\n"), "markdown",
                vim.tbl_extend("force", hover_cfg, {
                  focusable = true,
                  focus_id = "slang-hover",
                }))
            end)
          end, opts)
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
