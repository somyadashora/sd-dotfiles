return {
    "karb94/neoscroll.nvim",
    event = "WinScrolled",
    config = function()
      local neoscroll = require("neoscroll")
      neoscroll.setup({ easing = "quadratic", mappings = {} })
      local keymap = {
        ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 200, easing = "quadratic" }) end,
        ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 200, easing = "quadratic" }) end,
        ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 200, easing = "sine" }) end,
        ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 200, easing = "sine" }) end,
        ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 100 }) end,
        ["<C-e>"] = function() neoscroll.scroll(0.1, { move_cursor = false, duration = 100 }) end,
        ["zt"] = function() neoscroll.zt({ half_win_duration = 150 }) end,
        ["zz"] = function() neoscroll.zz({ half_win_duration = 150 }) end,
        ["zb"] = function() neoscroll.zb({ half_win_duration = 150 }) end,
      }
      for key, func in pairs(keymap) do vim.keymap.set({ "n", "v", "x" }, key, func) end
    end,
  }
