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

    -- Hover floats wear their own "ember" rust/orange identity (SdHover* in
    -- core/theme.lua) instead of the teal generic-panel NormalFloat, so a K
    -- box is instantly distinguishable from diagnostics/which-key floats and
    -- from the editor. open_floating_preview is the single choke point every
    -- hover path goes through (stock K and the slang macro-aware K below);
    -- keying off focus_id leaves diagnostic/signature floats on the teal
    -- panel look. Wrapped once here — this config() runs a single time.
    local hover_focus_ids = { ["textDocument/hover"] = true, ["slang-hover"] = true }
    -- vim.diagnostic.open_float sets focus_id to its scope; these mark a
    -- float as a diagnostic float in the same wrapper.
    local diag_focus_ids = { line = true, cursor = true, buffer = true }
    local diag_sev_names = { "Error", "Warn", "Info", "Hint" }
    local open_floating_preview = vim.lsp.util.open_floating_preview
    vim.lsp.util.open_floating_preview = function(contents, syntax, fopts, ...)
      local fbuf, fwin = open_floating_preview(contents, syntax, fopts, ...)
      if fopts and diag_focus_ids[fopts.focus_id]
        and fwin and vim.api.nvim_win_is_valid(fwin) then
        -- "Alert" identity (SdDiag* in core/theme.lua): border + solid title
        -- pill tinted by the worst severity the float is reporting. The
        -- current window is still the source window here (the float opens
        -- unfocused), so cursor-line diagnostics are the float's contents
        -- for line/cursor scope; buffer scope takes the whole buffer.
        local get_opts = fopts.focus_id ~= "buffer"
          and { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 } or nil
        local sev
        for _, d in ipairs(vim.diagnostic.get(0, get_opts)) do
          if not sev or d.severity < sev then sev = d.severity end
        end
        local name = diag_sev_names[sev] or "Info"
        local winhl = vim.wo[fwin].winhighlight
        if not winhl:find("SdDiagNormal", 1, true) then
          vim.wo[fwin].winhighlight = (winhl ~= "" and winhl .. "," or "")
            .. "NormalFloat:SdDiagNormal,FloatBorder:SdDiagBorder" .. name
        end
        -- Title needs a border to hang on — vim.diagnostic.config below sets
        -- rounded for all diagnostic floats; pcall covers border=none paths.
        pcall(vim.api.nvim_win_set_config, fwin, {
          title = { { " 󰒡 " .. name:lower() .. " ", "SdDiagTitle" .. name } },
          title_pos = "center",
        })
      elseif fopts and hover_focus_ids[fopts.focus_id]
        and fwin and vim.api.nvim_win_is_valid(fwin) then
        -- Pin the float's CONTENT to the ember scheme (kanagawa-dragon via
        -- theme.surface_schemes.hover) so the markdown + code fences stop
        -- rendering in the editor's pastels. Must happen BEFORE the
        -- winhighlight set below: styler reacts to OptionSet-winhighlight
        -- synchronously, and the sd_surface mark pin_surface plants is what
        -- stops it repinning this window to the pastel markdown theme.
        require("somya.core.theme").pin_surface(fwin, "hover")
        -- Append to (not replace) the winhighlight the float opened with —
        -- open_floating_preview sets its own entries (e.g. EndOfBuffer). A
        -- repeat K reuses the float and re-enters here; don't append twice.
        local winhl = vim.wo[fwin].winhighlight
        if not winhl:find("SdHoverNormal", 1, true) then
          vim.wo[fwin].winhighlight = (winhl ~= "" and winhl .. "," or "")
            .. "NormalFloat:SdHoverNormal,FloatBorder:SdHoverBorder,FloatTitle:SdHoverTitle"
        end
      end
      return fbuf, fwin
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        --
        -- Only definition + references get a g* map. Both SystemVerilog servers
        -- advertise exactly those two (checked via the initialize handshake):
        -- slang-server and verible-verilog-ls implement definition/references/
        -- documentSymbol/rename/codeAction and NOT declaration, implementation,
        -- or typeDefinition. Mapping the missing three would shadow real native
        -- motions (gD global-declaration search, gi insert-at-last-insert,
        -- gt next-tab) just to raise "no client supports" — so they are left
        -- alone here. Neovim 0.11+ already ships gri/grt/grn/gra/grr/gO as
        -- built-in LSP defaults for the servers that DO support them (lua_ls),
        -- and glance's gli/glt peek the same things.
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

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
        -- the SdHover* "ember" overrides in core/theme.lua (applied via the
        -- open_floating_preview wrapper above) make the box read as its own
        -- surface floating above the code. Press K a SECOND time to
        -- jump INTO the float (normal buffer: yank/search/visual all work),
        -- q closes it from inside (moving the cursor outside also closes it).
        -- The gold " 󰋗 hover " pill matches the other surfaces' title design
        -- (gitsigns neon, diagnostic alert); open_floating_preview passes
        -- title through whenever a border is set.
        local hover_cfg = {
          border = "rounded",
          max_width = 100,
          max_height = 30,
          title = { { " 󰋗 hover ", "SdHoverTitle" } },
          title_pos = "center",
        }

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
          -- Every slang map below ends in "a list of places in the design",
          -- so they all render through Trouble's qflist the same way.
          local function qf_open(title, items)
            vim.fn.setqflist({}, " ", { title = title, items = items })
            vim.cmd("Trouble qflist open")
          end

          -- An LSP Location -> quickfix entry. slang hands back {uri, range}
          -- under different field names per command, so callers pass the loc.
          local function qf_entry(loc, text)
            loc = loc or {}
            local r = loc.range and loc.range.start
            return {
              filename = loc.uri and vim.uri_to_fname(loc.uri) or "",
              lnum = r and r.line + 1 or 1,
              col = r and r.character + 1 or 1,
              text = text,
            }
          end

          -- slang exposes design queries through workspace/executeCommand.
          -- The argument shapes are undocumented AND inconsistent between
          -- commands — these were verified by probing slang-server 0.2.x over
          -- stdio, so don't "normalize" them to the LSP conventions:
          --   getInstancesOfModule  {"ModuleName"}              -> {{instPath, instLoc}}
          --   getInstances          {<TextDocumentPosition>}    -> {"top.u_inst", ...}
          --   getScope              {"top.u_inst"}              -> {{kind, instName, instLoc, type, value?}}
          --   expandMacros          {{src=<path>, dst=<path>}}  -> true (writes dst)
          -- getInstancesOfModule/getScope take a BARE STRING (an object errors
          -- with "could not cast to a string"), and expandMacros takes plain
          -- filesystem PATHS — a file:// URI gets "No such file or directory".
          local function slang_cmd(name, args, on_ok)
            local cl = vim.lsp.get_clients({ bufnr = 0, name = "slang-server" })[1]
            if not cl then return end
            cl:request("workspace/executeCommand",
              { command = "slang." .. name, arguments = args },
              function(err, res)
                if err then
                  vim.notify("Slang: " .. name .. " failed — "
                    .. (err.message or "unknown error"), vim.log.levels.ERROR)
                  return
                end
                on_ok(res)
              end)
          end

          -- Cursor position in the shape slang's position-taking commands want.
          local function cursor_params()
            local cl = vim.lsp.get_clients({ bufnr = 0, name = "slang-server" })[1]
            return cl and vim.lsp.util.make_position_params(0, cl.offset_encoding)
          end

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
                  qf_open((incoming and "Drivers of " or "Loads of ")
                    .. prep[1].name, qf)
                end)
              end)
            end
          end

          opts.desc = "Slang: trace signal drivers"
          keymap.set("n", "<leader>vd", slang_cone(true), opts)

          opts.desc = "Slang: trace signal loads"
          keymap.set("n", "<leader>vl", slang_cone(false), opts)

          -- Where is this module INSTANTIATED? gR/references answers "where is
          -- this name written" (declaration + every textual mention); this
          -- answers "where does it sit in the elaborated hierarchy", which is
          -- the question that actually comes up in bring-up. Rows are labelled
          -- with the hier path (top.u_core.u_fifo), not the file text.
          opts.desc = "Slang: instances of module under cursor"
          keymap.set("n", "<leader>vm", function()
            local mod = vim.fn.expand("<cword>")
            if mod == "" then return end
            slang_cmd("getInstancesOfModule", { mod }, function(res)
              if not res or #res == 0 then
                vim.notify("Slang: no instances of " .. mod
                  .. " (is it elaborated under the current top?)", vim.log.levels.WARN)
                return
              end
              local qf = {}
              for _, inst in ipairs(res) do
                qf[#qf + 1] = qf_entry(inst.instLoc, inst.instPath or "?")
              end
              qf_open("Instances of " .. mod, qf)
            end)
          end, opts)

          -- The inverse: what is the hierarchical path of the code I'm looking
          -- at? Yanked to + and " so it can be pasted straight into a waveform
          -- viewer search, a UVM config_db path, or a +plusarg.
          opts.desc = "Slang: yank hierarchical path of instance under cursor"
          keymap.set("n", "<leader>vp", function()
            local pos = cursor_params()
            if not pos then return end
            slang_cmd("getInstances", { pos }, function(res)
              if not res or #res == 0 then
                vim.notify("Slang: no elaborated instance under cursor",
                  vim.log.levels.WARN)
                return
              end
              local function yank(path)
                vim.fn.setreg("+", path)
                vim.fn.setreg('"', path)
                vim.notify("Slang: " .. path .. "  (yanked)")
              end
              -- One generic module can be instantiated many times; each is a
              -- distinct path, so let the user pick which one they meant.
              if #res == 1 then
                yank(res[1])
              else
                vim.ui.select(res, { prompt = "Instance path:" }, function(choice)
                  if choice then yank(choice) end
                end)
              end
            end)
          end, opts)

          -- Scope browser: every port/param/net in an elaborated scope, with
          -- its type and — for params — the RESOLVED value. Beats reading the
          -- source, which only shows the parameter expression.
          opts.desc = "Slang: browse scope (ports/params/nets)"
          keymap.set("n", "<leader>vs", function()
            local function show(path)
              slang_cmd("getScope", { path }, function(res)
                if not res or #res == 0 then
                  vim.notify("Slang: nothing in scope " .. path, vim.log.levels.WARN)
                  return
                end
                local qf = {}
                for _, sym in ipairs(res) do
                  local label = string.format("%-6s %s", sym.kind or "?",
                    sym.instName or "?")
                  if sym.type then label = label .. " : " .. sym.type end
                  if sym.value then label = label .. " = " .. sym.value end
                  qf[#qf + 1] = qf_entry(sym.instLoc, label)
                end
                qf_open("Scope " .. path, qf)
              end)
            end
            -- Default to the scope the cursor is actually in; fall back to
            -- asking, so any path in the design can be browsed from anywhere.
            local pos = cursor_params()
            if not pos then return end
            slang_cmd("getInstances", { pos }, function(res)
              if res and res[1] then
                show(res[1])
              else
                vim.ui.input({ prompt = "Slang scope path: ",
                  default = vim.fn.expand("<cword>") }, function(input)
                  if input and input ~= "" then show(input) end
                end)
              end
            end)
          end, opts)

          -- Fully macro-expanded view of the current file, side by side with
          -- the source. slang expands the file ON DISK into a temp file; we
          -- read it into a scratch buffer and drop the temp, so no stray file
          -- is left behind and no LSP client attaches to the expansion.
          opts.desc = "Slang: expand macros in this file"
          keymap.set("n", "<leader>vx", function()
            local src = vim.api.nvim_buf_get_name(0)
            if src == "" then return end
            if vim.bo.modified then
              vim.notify("Slang: expanding the file ON DISK — unsaved changes "
                .. "are not included", vim.log.levels.WARN)
            end
            local dst = vim.fn.tempname() .. "_" .. vim.fn.fnamemodify(src, ":t")
            slang_cmd("expandMacros", { { src = src, dst = dst } }, function()
              if vim.fn.filereadable(dst) == 0 then
                vim.notify("Slang: macro expansion produced no output",
                  vim.log.levels.ERROR)
                return
              end
              local lines = vim.fn.readfile(dst)
              vim.fn.delete(dst)
              local buf = vim.api.nvim_create_buf(false, true)
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
              vim.bo[buf].filetype = "systemverilog"
              vim.bo[buf].modifiable = false
              vim.bo[buf].bufhidden = "wipe"
              -- Names collide if the same file is expanded twice while the
              -- first view is still open — the name is cosmetic, so ignore it.
              pcall(vim.api.nvim_buf_set_name, buf,
                "slang://expanded/" .. vim.fn.fnamemodify(src, ":t"))
              vim.cmd("vsplit")
              vim.api.nvim_win_set_buf(0, buf)
            end)
          end, opts)

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
                -- Keep only sections that are really about the macro. slang's
                -- selectDisplayNode promotes a node to its parent when that
                -- parent is a TypedefDeclaration — and a `define's "parent" is
                -- whatever declaration FOLLOWS it (directives are trivia on the
                -- next token), so the "definition" fence often shows an
                -- unrelated typedef/struct from below the `define. The real
                -- definition fence always contains "`define", and the
                -- expansion sections announce themselves ("Expands to" /
                -- "Expanded from") — everything else (comment dumps, neighbor
                -- typedefs) is dropped.
                local sections = vim.split(md, "\n+%-%-%-\n+")
                local keep = { sections[1] }
                for i = 2, #sections do
                  if sections[i]:find("`define", 1, true)
                    or sections[i]:find("Expand", 1, true) then
                    keep[#keep + 1] = sections[i]
                  end
                end
                md = table.concat(keep, "\n\n---\n\n")
              end
              -- focus_id makes a repeat K (same buffer) FOCUS the open float
              -- instead of redrawing it — the same double-K behavior stock
              -- vim.lsp.buf.hover has — so its contents can be yanked.
              local _, fwin = vim.lsp.util.open_floating_preview(
                vim.split(md, "\n"), "markdown",
                vim.tbl_extend("force", hover_cfg, {
                  focusable = true,
                  focus_id = "slang-hover",
                }))
              -- Floats open with signcolumn=auto: any stray sign placed after
              -- focusing would pop a gutter open and shift the text. Pin it off.
              if fwin and vim.api.nvim_win_is_valid(fwin) then
                vim.wo[fwin].signcolumn = "no"
              end
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

    -- Diagnostic floats: rounded border (the frame the alert identity's
    -- border color + title pill hang on — see the wrapper above); show the
    -- producing server's name when more than one reports (verible vs slang).
    vim.diagnostic.config({
      float = { border = "rounded", source = "if_many" },
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
