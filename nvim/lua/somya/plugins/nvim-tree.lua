return {
  "nvim-tree/nvim-tree.lua",
  -- Lazy: load on first tree command or leader map. The <C-o> jumplist override
  -- (set in config) only matters once an NvimTree buffer exists, so deferring it
  -- until first open is harmless.
  cmd = {
    "NvimTreeToggle", "NvimTreeFindFileToggle", "NvimTreeCollapse",
    "NvimTreeRefresh", "NvimTreeResize", "NvimTreeFindFile", "NvimTreeFocus",
  },
  keys = {
    "<leader>ee", "<leader>ef", "<leader>ec", "<leader>er",
    "<leader>e=", "<leader>e-", "<leader>eh",
  },
  dependencies = "nvim-tree/nvim-web-devicons",
  -- Disable netrw at startup (not in config) so it stays disabled even though
  -- nvim-tree now loads lazily — init runs eagerly for lazy plugins too.
  init = function()
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    -- `nvim .` (or `nvim <dir>`): netrw is gone and nvim-tree is lazy, so a bare
    -- directory buffer would have nothing to hijack it. Detect a single directory
    -- argument and open the explorer on it at startup. File / no-arg launches
    -- stay lazy (loaded on the cmds/keys above).
    if vim.fn.argc(-1) == 1 then
      local arg = vim.fn.argv(0)
      if vim.fn.isdirectory(arg) == 1 then
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            require("nvim-tree.api").tree.open({ path = arg })
          end,
        })
      end
    end
  end,
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup({
      -- Keep every default in-tree mapping, but make `o` open-and-stay: it loads
      -- the file into a buffer and hops the cursor straight back to the tree, so
      -- you can run down the list pressing `o` to fan several files into separate
      -- buffers without leaving the explorer. `<CR>` still opens AND jumps to the
      -- file; `<Tab>` still previews.
      --
      -- We do NOT rely on api.node.open.edit's `focus` option — its meaning is
      -- inconsistent across nvim-tree versions and didn't reliably return focus
      -- here. Instead we remember the tree window, open the file (which moves the
      -- cursor onto it), then explicitly jump back to the tree window ourselves.
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "o", function()
          local tree_win = vim.api.nvim_get_current_win()
          api.node.open.edit(api.tree.get_node_under_cursor())
          if vim.api.nvim_win_is_valid(tree_win)
            and vim.api.nvim_get_current_win() ~= tree_win then
            vim.api.nvim_set_current_win(tree_win)
          end
        end, { desc = "nvim-tree: open (stay in tree)", buffer = bufnr, noremap = true, silent = true, nowait = true })
      end,
      -- Follow the tab-local working directory: :tcd (and switching into a tab
      -- with a different local dir) fires DirChanged, which re-roots the tree.
      -- Pairs with the <leader>TP / :TabProject scoped-tab flow in core/keymaps.
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      update_focused_file = {
        enable = true,
        update_root = true,
      },
      -- tab.sync is OFF on purpose (both open and close).
      --
      -- It mirrors the tree's open/closed state across ALL tabs. That fought our
      -- two scoped-tab flows badly:
      --   * close=true cascades a tree-close into every tab; for a no-file project
      --     tab whose only window is the tree, that closes the tab's last window
      --     and DESTROYS the tab — how <leader>wr restores were losing tabs.
      --   * open=true, during a session rebuild, races the per-tab tree opens
      --     (core/session_tabs.reconcile) and leaves some tabs treeless / fragile.
      -- We get the same "explorer is already visible in a new/restored project
      -- tab" behavior without sync: :TabProject opens the tree when it creates the
      -- tab, and reconcile() opens one in every tab it rebuilds.
      tab = {
        sync = {
          open = false,
          close = false,
        },
      },
      view = {
        width = 25,
        relativenumber = true,
        -- nvim-tree's own default is "yes" (2 cells); the tree has no signs, so
        -- reclaim that width for file names (statuscol ignores this ft).
        signcolumn = "no",
      },
      -- change folder arrow icons
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "+", -- arrow when folder is closed
              arrow_open = "-", -- arrow when folder is open
            },
          },
        },
      },
      -- disable window_picker for
      -- explorer to work well with
      -- window splits
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        custom = { ".DS_Store" },
      },
      git = {
        ignore = false,
      },
    })

    -- nvim-tree records "open files in THIS window" in a single GLOBAL
    -- (lib.target_winid), not per-tab, and its create-a-new-window check scans
    -- nvim_list_wins() across ALL tabs. So a tab whose only window is the tree
    -- has no usable window of its own and falls back to that global winid —
    -- which points at the last tab you opened a file in. Result: pressing <CR>
    -- on a file in tab A opens it over in tab B. Fix: whenever we enter a tab,
    -- drop a stale cross-tab target. 0 makes nvim-tree split a fresh window in
    -- the CURRENT tab; if the current tab already has a real (non-tree) window,
    -- get_target_winid() picks that one regardless, so 0 is always safe here.
    vim.api.nvim_create_autocmd({ "TabEnter", "TabNewEntered" }, {
      callback = function()
        local ok, lib = pcall(require, "nvim-tree.lib")
        if not ok then return end
        local id = lib.target_winid
        if id and id ~= 0 and vim.api.nvim_win_is_valid(id)
          and vim.api.nvim_win_get_tabpage(id) ~= vim.api.nvim_get_current_tabpage() then
          lib.target_winid = 0
        end
      end,
    })

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" })
    keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" })
    keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })
    keymap.set("n", "<leader>e=", "<cmd>NvimTreeResize +5<CR>", { desc = "Widen explorer" })
    keymap.set("n", "<leader>e-", "<cmd>NvimTreeResize -5<CR>", { desc = "Narrow explorer" })

    local function open_help()
      local K = 20  -- key column width
      local sections = {
        {
          title = "OPEN / NAVIGATE",
          entries = {
            { "<CR>",           "open file & jump to it (toggle dir)" },
            { "o",              "open file, stay in tree (fan into buffers)" },
            { "<C-v>",          "open in vertical split" },
            { "<C-x>",          "open in horizontal split" },
            { "<C-t>",          "open in new tab" },
            { "<Tab>",          "preview (stay in tree)" },
            { "P",              "jump to parent dir" },
            { "<BS>",           "close parent dir" },
          },
        },
        {
          title = "FILE OPERATIONS",
          entries = {
            { "a",              "create file / dir  (end with / for dir)" },
            { "d",              "delete" },
            { "r",              "rename" },
            { "x",              "cut" },
            { "c",              "copy" },
            { "p",              "paste" },
            { "y  /  Y",       "copy filename / relative path" },
            { "gy",             "copy absolute path" },
          },
        },
        {
          title = "VIEW / FILTER",
          entries = {
            { "I",              "toggle gitignored files" },
            { "H",              "toggle dotfiles" },
            { "f  /  F",       "live filter / clear filter" },
            { "E  /  W",       "expand all / collapse all" },
            { "R",              "refresh tree" },
            { "-",              "go up to parent directory" },
          },
        },
        {
          title = "GIT",
          entries = {
            { "]c  /  [c",     "next / prev git change" },
          },
        },
        {
          title = "MISC",
          entries = {
            { "<C-k>",          "show file info" },
            { "q",              "close tree window" },
            { "g?",             "full built-in help" },
          },
        },
        {
          title = "LEADER SHORTCUTS  (from anywhere)",
          entries = {
            { "<leader>ee",     "toggle tree" },
            { "<leader>ef",     "reveal current file in tree" },
            { "<leader>ec",     "collapse tree" },
            { "<leader>er",     "refresh tree" },
            { "<leader>e=  /  e-", "widen / narrow tree" },
            { "<leader>eh",     "this help" },
          },
        },
      }

      local function make_sep(title)
        local prefix = "  ── " .. title .. " "
        return prefix .. string.rep("─", math.max(4, 72 - #prefix))
      end

      local lines, hl_title = {}, {}
      for _, section in ipairs(sections) do
        table.insert(lines, make_sep(section.title))
        table.insert(hl_title, #lines)
        for _, entry in ipairs(section.entries) do
          local key, desc = entry[1], entry[2]
          local pad = string.rep(" ", math.max(2, K - #key))
          table.insert(lines, "  " .. key .. pad .. desc)
        end
        table.insert(lines, "")
      end

      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable = false
      vim.bo[buf].bufhidden = "wipe"

      local width  = math.min(76, math.floor(vim.o.columns * 0.88))
      local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.88))
      local row    = math.floor((vim.o.lines   - height) / 2)
      local col    = math.floor((vim.o.columns - width)  / 2)

      vim.api.nvim_open_win(buf, true, {
        relative  = "editor",
        width     = width,
        height    = height,
        row       = row,
        col       = col,
        style     = "minimal",
        border    = "rounded",
        title     = "  nvim-tree shortcuts  ",
        title_pos = "center",
      })

      local ns = vim.api.nvim_create_namespace("somya_nvimtree_help")
      for _, lnum in ipairs(hl_title) do
        vim.api.nvim_buf_add_highlight(buf, ns, "Title", lnum - 1, 0, -1)
      end

      for _, key in ipairs({ "q", "<Esc>", "<leader>eh" }) do
        vim.keymap.set("n", key, "<cmd>close<CR>", { buffer = buf, silent = true, nowait = true })
      end
    end

    keymap.set("n", "<leader>eh", open_help, { desc = "nvim-tree shortcuts help" })

    -- Ctrl-O jumps that land on an NvimTree entry trigger nvim-tree's split-protection,
    -- opening a second tree pane. Fix: skip those entries with :noautocmd (so nvim-tree's
    -- BufEnter handler doesn't fire for the intermediate buffers), then do the final real
    -- jump normally. setjumplist() doesn't exist in Neovim so we can't prune the list.
    keymap.set("n", "<C-o>", function()
      local list, pos = unpack(vim.fn.getjumplist())
      if pos == 0 then return end

      local skip = 0
      local idx  = pos - 1  -- 0-based index of the entry <C-o> would jump to
      while idx >= 0 do
        local entry = list[idx + 1]
        if not entry or not vim.api.nvim_buf_get_name(entry.bufnr):match("NvimTree_") then
          break
        end
        skip = skip + 1
        idx  = idx - 1
      end

      if idx < 0 then return end  -- only NvimTree entries remain, nowhere useful to go

      if skip > 0 then
        for _ = 1, skip do
          vim.cmd("noautocmd normal! \x0F")
        end
        -- noautocmd suppresses nvim-tree's own buflisted=false setter, which causes
        -- the NvimTree buffer to appear as a permanent tab in the bufferline.
        -- Re-apply it manually after the skip jumps.
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf):match("NvimTree_") then
            vim.bo[buf].buflisted = false
          end
        end
      end
      vim.cmd("normal! \x0F")
    end, { noremap = true, desc = "Jump back (skip NvimTree entries)" })
  end
}
