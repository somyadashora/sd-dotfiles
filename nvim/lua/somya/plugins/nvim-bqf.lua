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
        win_height = 14,
        win_vheight = 14,
        delay_syntax = 80,
        border = "rounded",
        show_title = true,
        should_preview_cb = function(bufnr)
          -- skip preview for very large files
          local ok, stat = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
          return not (ok and stat and stat.size > 1024 * 1024)
        end,
      },
      -- in-quickfix keymaps (buffer-local); see <leader>fH cheatsheet
      func_map = {
        open = "<CR>", -- open item under cursor
        openc = "o", -- open item and close quickfix
        split = "<C-x>", -- open in horizontal split
        vsplit = "<C-v>", -- open in vertical split
        tab = "<C-t>", -- open in new tab
        ptogglemode = "z,", -- toggle preview between normal/maximized
        pscrollup = "<C-b>", -- scroll preview up
        pscrolldown = "<C-f>", -- scroll preview down
        prevfile = "<C-p>", -- preview prev file's first item
        nextfile = "<C-n>", -- preview next file's first item
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
