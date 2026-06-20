return {
  "kevinhwang91/nvim-bqf",
  ft = "qf", -- load when a quickfix/location-list window opens
  dependencies = {
    -- bqf's fzf filter needs the junegunn/fzf *Vim plugin* (provides fzf#run),
    -- not just the fzf binary. Without it, pressing zf throws at fzf.lua:573.
    -- No build step: fzf#run uses the system fzf already on PATH.
    "junegunn/fzf",
  },
  config = function()
    -- Only enable the fzf filter when fzf#run is actually available; all other
    -- bqf features (preview, splits, navigation) work without it.
    local has_fzf = vim.fn.exists("*fzf#run") == 1

    require("bqf").setup({
      auto_enable = true,
      auto_resize_height = true, -- shrink/grow the qf window to fit its contents
      preview = {
        auto_preview = false, -- no preview popup window (was distracting)
      },
      -- in-quickfix keymaps (buffer-local); see <leader>fH cheatsheet
      func_map = {
        open = "<CR>", -- open item under cursor
        openc = "o", -- open item and close quickfix
        split = "<C-x>", -- open in horizontal split
        vsplit = "<C-v>", -- open in vertical split
        tab = "<C-t>", -- open in new tab
        -- Mark entries, then build a NEW quickfix list from the marks. The list
        -- you filtered FROM is pushed onto the qf stack (not lost) — get it back
        -- with :colder (<leader>q[) / :cnewer (<leader>q]).
        stoggledown = "<Tab>", -- toggle mark on entry, move down
        stoggleup = "<S-Tab>", -- toggle mark on entry, move up
        sclear = "z<Tab>", -- clear all marks
        filter = "zn", -- new list from MARKED entries
        filterr = "zN", -- new list from UNMARKED entries
        fzffilter = has_fzf and "zf" or "", -- fzf fuzzy-filter (only if fzf present)
      },
      filter = {
        fzf = {
          action_for = {
            ["ctrl-x"] = "split",
            ["ctrl-v"] = "vsplit",
            ["ctrl-t"] = "tab drop",
            ["ctrl-q"] = "signtoggle", -- toggle marks inside fzf
          },
          extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "bqf> " },
        },
      },
    })
  end,
}
