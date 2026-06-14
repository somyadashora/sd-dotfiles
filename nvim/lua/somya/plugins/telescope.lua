return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- Open ALL Tab-marked entries on <CR>; fall back to default for a single entry
    local function select_one_or_multi(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local multi = picker:get_multi_selection()
      if not vim.tbl_isempty(multi) then
        actions.close(prompt_bufnr)
        for _, entry in ipairs(multi) do
          local fname = entry.path or entry.filename
          if fname then
            vim.cmd("edit " .. vim.fn.fnameescape(fname))
            if entry.lnum then
              pcall(vim.api.nvim_win_set_cursor, 0, { entry.lnum, math.max((entry.col or 1) - 1, 0) })
            end
          end
        end
      else
        actions.select_default(prompt_bufnr)
      end
    end

    telescope.setup({
      defaults = {
        dynamic_preview_title = true,
        layout_strategy = "horizontal",
        layout_config = {
          width = 0.90,
          height = 0.92,
          preview_width = 0.6,
        },
        path_display = { "smart" },
        preview = {
          -- enable/disable tree-sitter highlighting in preview (compatibility issue with ft_to_lang. currently enabledP)
          treesitter = true,
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<CR>"] = select_one_or_multi, -- open all Tab-marked entries
          },
          n = {
            ["<CR>"] = select_one_or_multi, -- open all Tab-marked entries
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- show line numbers in the preview window (skip help pages)
    vim.api.nvim_create_autocmd("User", {
      pattern = "TelescopePreviewerLoaded",
      callback = function(args)
        if not (args.data and args.data.filetype == "help") then
          vim.wo.number = true
        end
      end,
    })

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fFi", function()
      require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
    end, { desc = "Fuzzy find files in cwd, including hidden and gitignored" })

    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })

    keymap.set("n", "<leader>fs", function()
      require("telescope.builtin").live_grep(require("telescope.themes").get_ivy())
    end, { desc = "Find string in cwd" })
    -- keymap.set("n", "<leader>fSi", "<cmd>Telescope live_grep no_ignore=true hidden=true<cr>", { desc = "Find string in cwd, don't respect gitignore" })

    keymap.set("n", "<leader>*", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })

    keymap.set("n", "<leader>B", function()
      require("telescope.builtin").buffers({
        initial_mode = "normal",
        attach_mappings = function(_, map)
          map("n", "d", actions.delete_buffer) -- close buffer under cursor with d
          return true
        end,
      })
    end, { desc = "Open buffer picker (normal mode, d=close)" })
    keymap.set("n", '<leader>"', "<cmd>Telescope registers<cr>", { desc = "Find registers in registerlist" })
    keymap.set("n", "<leader>j", "<cmd>Telescope jumplist<cr>", { desc = "Find jumps in jumplist" })
    keymap.set("n", "<leader>`", function()
      require("telescope.builtin").marks(require("telescope.themes").get_ivy())
    end, { desc = "Find marks in marklist" })
    keymap.set("n", "<leader>fT", "<cmd>TodoTelescope<cr>", { desc = "Find Todo's" })
    keymap.set("n", "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Find string fuzzily in current buffer" })
    keymap.set("n", "<leader>:", "<cmd>Telescope command_history<cr>", { desc = "Find in command history" })
    keymap.set("n", "<leader>?", "<cmd>Telescope help_tags<cr>", { desc = "Find help tags" })
    keymap.set("n", "<leader>q", "<cmd>Telescope quickfix<cr>", { desc = "Find in quickfix list" })

    keymap.set("n", "<leader>;", function()
      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local entry_display = require("telescope.pickers.entry_display")

      local raw, cur_idx = unpack(vim.fn.getchangelist(vim.fn.bufnr("%")))
      if #raw == 0 then
        vim.notify("Changelist is empty", vim.log.levels.INFO)
        return
      end

      -- reverse so most-recent change is first; mark current position
      local entries = {}
      for i = #raw, 1, -1 do
        local e = raw[i]
        local line = vim.fn.getline(e.lnum) or ""
        table.insert(entries, {
          lnum = e.lnum,
          col  = e.col,
          text = vim.trim(line),
          idx  = i,
          current = (i == cur_idx),
        })
      end

      local displayer = entry_display.create({
        separator = " ",
        items = { { width = 2 }, { width = 6 }, { remaining = true } },
      })

      pickers.new({}, {
        prompt_title = "Changelist",
        finder = finders.new_table({
          results = entries,
          entry_maker = function(e)
            return {
              value   = e,
              display = function(entry)
                return displayer({
                  { entry.value.current and ">" or " ", "TelescopeResultsIdentifier" },
                  { tostring(entry.value.lnum), "TelescopeResultsLineNr" },
                  entry.value.text,
                })
              end,
              ordinal = e.lnum .. " " .. e.text,
              lnum    = e.lnum,
              col     = e.col,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(_, map)
          map("i", "<CR>", function(prompt_bufnr)
            local sel = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(prompt_bufnr)
            vim.api.nvim_win_set_cursor(0, { sel.lnum, sel.col })
          end)
          return true
        end,
      }):find()
    end, { desc = "Find in changelist" })
  end,
}
