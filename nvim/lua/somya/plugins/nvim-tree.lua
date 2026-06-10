return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup({
      view = {
        width = 25,
        relativenumber = true,
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
            { "<CR>  /  o",     "open file or toggle dir" },
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

      for _ = 1, skip do
        vim.cmd("noautocmd normal! \x0F")  -- advance past NvimTree silently
      end
      vim.cmd("normal! \x0F")             -- final real jump with autocmds
    end, { noremap = true, desc = "Jump back (skip NvimTree entries)" })
  end
}
