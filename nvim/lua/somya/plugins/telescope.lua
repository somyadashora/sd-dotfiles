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

    telescope.setup({
      defaults = {
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
          },
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
    keymap.set("n", "<leader>fFi", function()
      require("telescope.builtin").find_files({ hidden = true, no_ignore = true })
    end, { desc = "Fuzzy find files in cwd, including hidden and gitignored" })

    keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })

    keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
    -- keymap.set("n", "<leader>fSi", "<cmd>Telescope live_grep no_ignore=true hidden=true<cr>", { desc = "Find string in cwd, don't respect gitignore" })

    keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })

    keymap.set("n", "<leader>fB", "<cmd>Telescope buffers<cr>", { desc = "Find buffers in bufferlist" })
    keymap.set("n", "<leader>fR", "<cmd>Telescope registers<cr>", { desc = "Find registers in registerlist" })
    keymap.set("n", "<leader>fJ", "<cmd>Telescope jumplist<cr>", { desc = "Find jumps in jumplist" })
    keymap.set("n", "<leader>fM", "<cmd>Telescope marks<cr>", { desc = "Find marks in marklist" })
    keymap.set("n", "<leader>fT", "<cmd>TodoTelescope<cr>", { desc = "Find Todo's" })
    keymap.set("n", "<leader>fib", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Find string fuzzily in current buffer" })
  end,
}
