return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- "SD-NVIM" in ANSI-shadow block letters (the █████ in the gap is the dash).
    local header_lines = {
      [[███████╗██████╗       ███╗   ██╗██╗   ██╗██╗███╗   ███╗]],
      [[██╔════╝██╔══██╗      ████╗  ██║██║   ██║██║████╗ ████║]],
      [[███████╗██║  ██║ ████ ██╔██╗ ██║██║   ██║██║██╔████╔██║]],
      [[╚════██║██║  ██║ ████ ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║]],
      [[███████║██████╔╝      ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║]],
      [[╚══════╝╚═════╝       ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
    }

    vim.api.nvim_set_hl(0, "SdNvimHelp", { fg = "#7f8bb0" })

    -- Everything visual is re-rolled on each dashboard draw so every launch looks
    -- different:
    --   • box accent  — bg of the date/machine pills (+ subheader/footer tint)
    --   • window bg   — the whole dashboard background (applied via winhighlight)
    --   • gradient    — a 6-color slice of a colour ring, taken from a random
    --                   start, recolours the SD-NVIM art.
    local box_palette = {
      "#94e2d5", "#cba6f7", "#fab387", "#a6e3a1", "#89b4fa", "#f5c2e7", "#f9e2af",
    }
    local bg_palette = {
      "#1e1e2e", "#1a1b26", "#232136", "#11171c", "#1c1917", "#181f1a", "#1f1a24",
    }
    -- ordered so any 6 consecutive colours flow into a pleasant gradient
    local grad_ring = {
      "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5", "#89dceb",
      "#74c7ec", "#89b4fa", "#b4befe", "#cba6f7", "#f5c2e7", "#eba0ac",
    }
    math.randomseed(vim.loop.hrtime() % 2147483647)

    local last_accent
    local function reroll()
      -- box accent (avoid an immediate repeat)
      local ai = math.random(#box_palette)
      while #box_palette > 1 and ai == last_accent do
        ai = math.random(#box_palette)
      end
      last_accent = ai
      local accent = box_palette[ai]
      vim.api.nvim_set_hl(0, "SdNvimBox", { fg = "#11111b", bg = accent, bold = true })
      vim.api.nvim_set_hl(0, "SdNvimSub", { fg = accent, italic = true })
      vim.api.nvim_set_hl(0, "SdNvimFooter", { fg = accent, italic = true })

      -- whole-window background
      local bg = bg_palette[math.random(#bg_palette)]
      vim.api.nvim_set_hl(0, "SdNvimDashBg", { bg = bg, fg = "#c0caf5" })

      -- gradient slice for the SD-NVIM art
      local start = math.random(#grad_ring)
      for i = 1, 6 do
        local c = grad_ring[(start + i - 2) % #grad_ring + 1]
        vim.api.nvim_set_hl(0, "SdNvimGrad" .. i, { fg = c, bold = true })
      end
    end
    reroll()

    -- Re-roll just before each (re)draw — FileType fires while alpha builds the
    -- buffer, before the screen redraws, so the new colours take hold. Also paint
    -- the window background here (winhighlight is window-local) and clear it again
    -- when the dashboard leaves the window, so the tint never leaks into files.
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "alpha",
      callback = function(ev)
        reroll()
        local win = vim.api.nvim_get_current_win()
        vim.wo[win].winhighlight =
          "Normal:SdNvimDashBg,NormalNC:SdNvimDashBg,EndOfBuffer:SdNvimDashBg,SignColumn:SdNvimDashBg"
        vim.api.nvim_create_autocmd({ "BufWinLeave", "BufHidden" }, {
          buffer = ev.buf,
          once = true,
          callback = function()
            if vim.api.nvim_win_is_valid(win) then
              vim.wo[win].winhighlight = ""
            end
          end,
        })
      end,
    })

    local function boxed(s) return "  " .. s .. "  " end

    -- Date/time (captured at startup) and a one-line machine summary. ASCII
    -- separators only, so alpha's centering matches what the terminal draws.
    local function datetime()
      return os.date("%A, %d %b %Y   |   %H:%M")
    end
    local function sysinfo()
      local u = vim.loop.os_uname()
      local host = vim.loop.os_gethostname() or "?"
      local user = (vim.loop.os_get_passwd() or {}).username or os.getenv("USER") or "?"
      local nvim = vim.version()
      local cores = #(vim.loop.cpu_info() or {})
      local gb = vim.loop.get_total_memory() / (1024 ^ 3)
      return string.format("%s@%s   |   %s %s   |   %d cores  %.0f GB   |   nvim %d.%d.%d",
        user, host, u.sysname, u.machine, cores, gb, nvim.major, nvim.minor, nvim.patch)
    end

    local header_hl = {}
    for i = 1, #header_lines do
      header_hl[i] = { { "SdNvimGrad" .. i, 0, -1 } }
    end

    local header = {
      type = "text",
      val = header_lines,
      opts = { position = "center", hl = header_hl },
    }

    local subheader = {
      type = "text",
      val = "« nVim for Chip Design - by Somya Dashora »",
      opts = { position = "center", hl = "SdNvimSub" },
    }

    -- Table-form hl ({{group, 0, -1}}) so alpha offsets the highlight by the
    -- centering pad and the box hugs only the text — a string hl would paint
    -- from the left window edge instead.
    local datenode = {
      type = "text",
      val = boxed(datetime()),
      opts = { position = "center", hl = { { "SdNvimBox", 0, -1 } } },
    }

    local infonode = {
      type = "text",
      val = boxed(sysinfo()),
      opts = { position = "center", hl = { { "SdNvimBox", 0, -1 } } },
    }

    -- Each button: a letter to press here + the equivalent <leader> keymap, so
    -- the dashboard doubles as an onboarding cheat-card.
    local function btn(sc, icon, label, hint, cmd)
      local b = dashboard.button(sc, string.format("%s  %-22s %s", icon, label, hint), cmd)
      b.opts.hl = "Function"
      b.opts.hl_shortcut = "Keyword"
      b.opts.width = 52
      return b
    end

    local buttons = {
      type = "group",
      val = {
        btn("f", "󰈞", "Find file", "<leader>ff", "<cmd>Telescope find_files<CR>"),
        btn("r", "󰋚", "Recent files", "<leader>fr", "<cmd>Telescope oldfiles<CR>"),
        btn("g", "󰊄", "Live grep", "<leader>fs", "<cmd>Telescope live_grep<CR>"),
        btn("e", "", "File explorer", "<leader>ee", "<cmd>NvimTreeToggle<CR>"),
        btn("H", "󰋗", "Cheatsheet (all keys)", "<leader>fH", "<cmd>Cheatsheet<CR>"),
        btn("Q", "󰘬", "Quickfix :cdo help", "<leader>qh", "<cmd>QfHelp<CR>"),
        btn("l", "󰒲", "Plugins (Lazy)", "", "<cmd>Lazy<CR>"),
        btn("q", "󰗼", "Quit", "", "<cmd>qa<CR>"),
      },
      opts = { spacing = 1 },
    }

    local help = {
      type = "text",
      val = {
        "leader = <Space>   ·   press it for grouped menus (which-key)",
        "<leader>fH cheatsheet    <leader>qh quickfix :cdo/:cfdo help",
        "<leader>tt terminal   <leader>xs symbols   <leader>va code action",
      },
      opts = { position = "center", hl = "SdNvimHelp" },
    }

    local footer = {
      type = "text",
      val = "loading…",
      opts = { position = "center", hl = "SdNvimFooter" },
    }

    alpha.setup({
      layout = {
        { type = "padding", val = 2 },
        header,
        { type = "padding", val = 1 },
        subheader,
        { type = "padding", val = 1 },
        datenode,
        infonode,
        { type = "padding", val = 2 },
        buttons,
        { type = "padding", val = 1 },
        help,
        { type = "padding", val = 1 },
        footer,
      },
      opts = { margin = 5 },
    })

    -- Fill the footer with lazy's load stats once everything is ready.
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        local ok, lazy = pcall(require, "lazy")
        if not ok then
          return
        end
        local stats = lazy.stats()
        local ms = math.floor((stats.startuptime or 0) * 100 + 0.5) / 100
        footer.val = string.format("⚡ %d/%d plugins loaded in %sms", stats.loaded, stats.count, ms)
        datenode.val = boxed(datetime()) -- refresh now that startup has settled
        pcall(vim.cmd, "AlphaRedraw")
      end,
    })
  end,
}
