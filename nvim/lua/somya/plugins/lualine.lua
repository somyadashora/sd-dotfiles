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
    -- CursorMoved sets a pending flag; the slide defers to the next keypress so the
    -- completed command always gets one render cycle in bright yellow first.
    -- nmode_needs_arg: after a prefix key (`, ', ", @, r, f, F, t, T, m) the very
    -- next character is an argument, not a new command — suppress the slide so the
    -- pair stays together (e.g. `5 and "5p stay as one unit).
    local nmode_prev = ""
    local nmode_curr = ""
    local nmode_slide_pending = false
    local nmode_needs_arg = false
    local nmode_timer = nil

    -- keys that consume one following character as an argument (mark/register/char)
    local AWAITS_CHAR = {
      ["`"]=true, ["'"]=true, ['"']=true, ["@"]=true,
      ["r"]=true, ["f"]=true, ["F"]=true, ["t"]=true, ["T"]=true, ["m"]=true,
    }

    local function reset_nmode()
      nmode_prev = ""
      nmode_curr = ""
      nmode_slide_pending = false
      nmode_needs_arg = false
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
      -- slide prev command to dim; skip while consuming a multi-key argument
      if nmode_slide_pending and mode == "n" and not nmode_needs_arg then
        nmode_prev = (nmode_prev .. nmode_curr):sub(-24)
        nmode_curr = ""
        nmode_slide_pending = false
      end
      nmode_curr = nmode_curr .. k
      -- keep total display ≤ 24 chars, trimming from the oldest (prev) end
      local over = #nmode_prev + #nmode_curr - 24
      if over > 0 then
        nmode_prev = #nmode_prev > over and nmode_prev:sub(over + 1) or ""
      end
      -- update needs_arg state
      if nmode_needs_arg then
        nmode_needs_arg = false          -- argument consumed
      elseif mode == "n" and AWAITS_CHAR[k] then
        nmode_needs_arg = true           -- next key is the argument
        nmode_slide_pending = false      -- clear any stale pending so CursorMoved between
                                         -- prefix and arg doesn't split the pair
      end
      restart_timer()
    end)

    -- Mark that a command completed; actual slide deferred to next keypress
    vim.api.nvim_create_autocmd("CursorMoved", {
      callback = function()
        if vim.fn.mode() == "n" then nmode_slide_pending = true end
      end,
    })

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
