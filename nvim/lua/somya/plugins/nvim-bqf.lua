return {
  "kevinhwang91/nvim-bqf",
  ft = "qf", -- load when a quickfix/location-list window opens
  config = function()
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
        fzffilter = "zf", -- fuzzy-filter the quickfix list with fzf
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
