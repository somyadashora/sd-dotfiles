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

    -- nmode_prev: completed commands (dim)   nmode_curr: keys being built (bright)
    --
    -- Slide detection: at the top of every vim.on_key callback we call
    -- nvim_win_get_cursor(). Because vim.on_key fires BEFORE the current key is
    -- processed, the cursor position already reflects the PREVIOUS key's execution.
    -- If it changed since the last callback, the previous key was a completed motion
    -- and we slide curr → prev.  This works even for rapid key sequences (CursorMoved
    -- fires asynchronously and misses those; position comparison never does).
    -- Prefix keys (`, ", f, …) don't move the cursor, so their argument char is
    -- naturally kept in curr — no explicit AWAITS_CHAR table needed.
    local nmode_prev = ""
    local nmode_curr = ""
    local nmode_last_row = nil
    local nmode_last_col = nil
    local nmode_timer = nil

    local function reset_nmode()
      nmode_prev = ""
      nmode_curr = ""
      nmode_last_row = nil
      nmode_last_col = nil
      if nmode_timer then nmode_timer:stop(); nmode_timer:close(); nmode_timer = nil end
    end

    local function restart_timer()
      if nmode_timer then nmode_timer:stop(); nmode_timer:close() end
      nmode_timer = vim.uv.new_timer()
      nmode_timer:start(20000, 0, vim.schedule_wrap(reset_nmode))
    end

    vim.on_key(function(key)
      local mode = vim.fn.mode()
      if mode ~= "n" and mode ~= "no" and mode ~= "v" and mode ~= "V" and mode ~= "\22" then return end
      local k = vim.fn.keytrans(key)
      if k == "" then return end
      -- drop raw bytes (<CE>, <C4>, <80>…) and terminal escape codes (<t_…>)
      if k:match("^<[0-9A-Fa-f][0-9A-Fa-f]>$") or k:match("^<t_") then return end

      -- compare current cursor pos with where it was when the previous key fired;
      -- a change means the previous key was a completed command → slide to dim
      local ok, pos = pcall(vim.api.nvim_win_get_cursor, 0)
      if ok and nmode_last_row ~= nil and mode == "n" then
        if pos[1] ~= nmode_last_row or pos[2] ~= nmode_last_col then
          nmode_prev = (nmode_prev .. nmode_curr):sub(-24)
          nmode_curr = ""
        end
      end
      if ok then nmode_last_row, nmode_last_col = pos[1], pos[2] end

      nmode_curr = nmode_curr .. k
      -- keep total display ≤ 24 chars, trimming from the oldest (prev) end
      local over = #nmode_prev + #nmode_curr - 24
      if over > 0 then
        nmode_prev = #nmode_prev > over and nmode_prev:sub(over + 1) or ""
      end
      restart_timer()
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
            function() return nmode_prev end,
            cond = function() return nmode_prev ~= "" end,
            color = { fg = "#5c7a8c", gui = "bold" },   -- dim: history
          },
          {
            function() return nmode_curr end,
            cond = function() return nmode_curr ~= "" end,
            color = { fg = colors.yellow, gui = "bold" }, -- bright: current command
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
        lualine_z = {
          { "location" },
        },
      },
    })
  end,
}
