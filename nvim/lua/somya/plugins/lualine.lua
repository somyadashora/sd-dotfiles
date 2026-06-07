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
    -- Boundary detection uses three signals, checked at the top of every vim.on_key
    -- callback (which fires BEFORE the current key is processed, so cursor/mode already
    -- reflect the PREVIOUS key's execution):
    --   1. Cursor moved → previous key was a completed motion → slide curr to prev.
    --   2. Mode returned to "n" from "no" (operator-pending) → operator+motion completed
    --      even without cursor movement (e.g. d<Esc> cancel).
    --   3. nmode_curr_done flag → previous key was self-terminating (<Esc>) or completed
    --      a prefix+char pair (ma, ra) that doesn't move the cursor.
    local nmode_prev = ""
    local nmode_curr = ""
    local nmode_last_row = nil
    local nmode_last_col = nil
    local nmode_timer = nil
    local nmode_curr_done = false   -- current nmode_curr is a complete command
    local nmode_prev_mode = nil     -- mode() value recorded on previous key
    local nmode_awaiting_char = false -- next char completes a prefix+char command

    -- Keys that end a command by themselves (no cursor movement, no mode change).
    local NMODE_SELF_TERM = { ["<Esc>"] = true }
    -- Prefix keys whose NEXT char completes them.
    -- ` and ' move the cursor (mark jump), but marking done early prevents bundling
    -- with the subsequent command when the jump lands at the same position.
    local NMODE_AWAITS_CHAR = { m = true, r = true, ["`"] = true, ["'"] = true }
    -- Mark-jump prefixes: when pressed in pure normal mode with only count digits
    -- in nmode_curr, force a slide first so `5`5` doesn't appear as one bright unit.
    local NMODE_JUMP_PREFIXES = { ["`"] = true, ["'"] = true }

    vim.g.nmode_history = true  -- toggled by <leader>K

    local function reset_nmode()
      nmode_prev = ""
      nmode_curr = ""
      nmode_last_row = nil
      nmode_last_col = nil
      nmode_curr_done = false
      nmode_prev_mode = nil
      nmode_awaiting_char = false
      if nmode_timer then nmode_timer:stop(); nmode_timer:close(); nmode_timer = nil end
    end

    local function restart_timer()
      if nmode_timer then nmode_timer:stop(); nmode_timer:close() end
      nmode_timer = vim.uv.new_timer()
      nmode_timer:start(5000, 0, vim.schedule_wrap(reset_nmode))
    end

    vim.on_key(function(key)
      local mode = vim.fn.mode(1)
      if mode ~= "n" and mode ~= "no" and mode ~= "v" and mode ~= "V" and mode ~= "\22" then
        nmode_prev_mode = nil  -- invalidate stale mode when leaving tracked modes
        return
      end
      local k = vim.fn.keytrans(key)
      if k == "" then return end
      -- drop raw bytes (<CE>, <C4>, <80>…) and terminal escape codes (<t_…>)
      if k:match("^<[0-9A-Fa-f][0-9A-Fa-f]>$") or k:match("^<t_") then return end

      -- All signals below reflect the PREVIOUS key's result (on_key fires before
      -- the current key is processed).
      local ok, pos = pcall(vim.api.nvim_win_get_cursor, 0)
      local cursor_moved = ok and nmode_last_row ~= nil and mode == "n"
        and (pos[1] ~= nmode_last_row or pos[2] ~= nmode_last_col)
      local mode_returned = nmode_prev_mode ~= nil and nmode_prev_mode ~= "n" and mode == "n"
      -- If a mark-jump prefix (` ') arrives while nmode_curr is pure count digits in
      -- normal mode, slide the orphaned digits first — prevents `5`5` bundling.
      local jump_prefix_slide = NMODE_JUMP_PREFIXES[k] and mode == "n"
        and nmode_curr:match("^%d+$") ~= nil

      if cursor_moved or mode_returned or nmode_curr_done or jump_prefix_slide then
        nmode_prev = (nmode_prev .. nmode_curr):sub(-24)
        nmode_curr = ""
        nmode_curr_done = false
        nmode_awaiting_char = false
      end
      if ok then nmode_last_row, nmode_last_col = pos[1], pos[2] end
      nmode_prev_mode = mode

      nmode_curr = nmode_curr .. k

      -- Update completion state for the new key.
      if nmode_awaiting_char then
        -- This char completes a prefix+char command (e.g. ma, ra).
        nmode_curr_done = true
        nmode_awaiting_char = false
      elseif NMODE_SELF_TERM[k] then
        nmode_curr_done = true
      elseif NMODE_AWAITS_CHAR[k] then
        nmode_awaiting_char = true
      end

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
            cond = function() return nmode_prev ~= "" and vim.g.nmode_history end,
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
