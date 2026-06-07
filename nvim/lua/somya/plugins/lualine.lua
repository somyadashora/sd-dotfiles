return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status") -- to configure lazy pending updates count

    local colors = {
      blue = "#65D1FF",
      green = "#3EFFDC",
      violet = "#FF61EF",
      yellow = "#FFDA7B",
      red = "#FF4A4A",
      fg = "#c3ccdc",
      bg = "#112638",
      inactive_bg = "#2c3043",
    }

    local my_lualine_theme = {
      normal = {
        a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      insert = {
        a = { bg = colors.green, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      visual = {
        a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      command = {
        a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      replace = {
        a = { bg = colors.red, fg = colors.bg, gui = "bold" },
        b = { bg = colors.bg, fg = colors.fg },
        c = { bg = colors.bg, fg = colors.fg },
      },
      inactive = {
        a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
        b = { bg = colors.inactive_bg, fg = colors.semilightgray },
        c = { bg = colors.inactive_bg, fg = colors.semilightgray },
      },
    }

    local mode_labels = {
      n = "NORMAL", no = "N-OP", v = "VISUAL", V = "V-LINE",
      ["\22"] = "V-BLOCK", i = "INSERT", ic = "INSERT",
      R = "REPLACE", Rv = "V-REPLACE", c = "COMMAND",
      s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK", t = "TERMINAL",
    }

    -- Accumulate normal/visual-mode keystrokes; clear 2 s after last key or on insert entry
    local nmode_keys = ""
    local nmode_timer = nil
    local function reset_nmode()
      nmode_keys = ""
      if nmode_timer then nmode_timer:stop(); nmode_timer:close(); nmode_timer = nil end
    end

    vim.on_key(function(key)
      local mode = vim.fn.mode()
      if mode ~= "n" and mode ~= "v" and mode ~= "V" and mode ~= "\22" then return end
      local k = vim.fn.keytrans(key)
      if k == "" then return end
      nmode_keys = nmode_keys .. k
      if #nmode_keys > 24 then nmode_keys = nmode_keys:sub(-24) end
      if nmode_timer then nmode_timer:stop(); nmode_timer:close() end
      nmode_timer = vim.uv.new_timer()
      nmode_timer:start(2000, 0, vim.schedule_wrap(reset_nmode))
    end)

    local function screenkey_status()
      if vim.g.screenkey_active then return "󰌌 KEYS" end
      return ""
    end

    -- configure lualine with modified theme
    lualine.setup({
      options = {
        theme = my_lualine_theme,
      },
      sections = {
        lualine_a = {
          {
            function()
              if vim.g.vm_active then return "MULTI" end
              return mode_labels[vim.fn.mode()] or vim.fn.mode():upper()
            end,
            color = function()
              if vim.g.vm_active then
                return { bg = "#f38ba8", fg = "#1e1e2e", gui = "bold" }
              end
            end,
          },
        },
        lualine_c = {
          { "filename" },
          {
            function() return nmode_keys end,
            cond = function() return nmode_keys ~= "" end,
            color = { fg = colors.yellow, gui = "bold" },
          },
        },
        lualine_x = {
          {
            function()
              if not vim.g.code_review_visible then return "" end
              local ok, review = pcall(require, "review")
              if not ok then return "" end
              local count = review.count()
              if count == 0 then return "" end
              return "󰍉 " .. count
            end,
            color = { fg = "#f9e2af", gui = "bold" },
          },
          {
            screenkey_status,
            color = { fg = colors.yellow, gui = "bold" },
          },
          {
            "encoding",
          },
          {
            "fileformat",
          },
          {
            "filetype",
          },
        },
      },
    })
  end,
}
