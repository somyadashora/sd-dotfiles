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

    -- Cool purple→teal gradient (one hl per row), plus accent groups. Defined
    -- here so they sit on top of whatever colorscheme loaded before VimEnter.
    local grad = { "#c099ff", "#a99cf0", "#8fb0f5", "#74bdf0", "#6ad3df", "#94e2d5" }
    for i, c in ipairs(grad) do
      vim.api.nvim_set_hl(0, "SdNvimGrad" .. i, { fg = c, bold = true })
    end
    vim.api.nvim_set_hl(0, "SdNvimHelp", { fg = "#7f8bb0" })
    vim.api.nvim_set_hl(0, "SdNvimFooter", { fg = "#cba6f7", italic = true })

    -- The date/time and machine lines sit in a colored "box" (dark text on an
    -- accent background, like the cheatsheet key pills). A fresh accent is rolled
    -- from this catppuccin palette on every dashboard draw, so each launch looks
    -- a little different. The subheader is tinted to match for cohesion.
    local box_palette = {
      "#94e2d5", "#cba6f7", "#fab387", "#a6e3a1", "#89b4fa", "#f5c2e7", "#f9e2af",
    }
    math.randomseed(vim.loop.hrtime() % 2147483647)
    local last_idx
    local function reroll_accent()
      local idx = math.random(#box_palette)
      while #box_palette > 1 and idx == last_idx do
        idx = math.random(#box_palette)
      end
      last_idx = idx
      local c = box_palette[idx]
      vim.api.nvim_set_hl(0, "SdNvimBox", { fg = "#181825", bg = c, bold = true })
      vim.api.nvim_set_hl(0, "SdNvimSub", { fg = c, italic = true })
    end
    reroll_accent()
    -- Re-roll just before each (re)draw — FileType fires while alpha builds the
    -- buffer, before it applies the node highlights, so the new color takes hold.
    vim.api.nvim_create_autocmd("FileType", { pattern = "alpha", callback = reroll_accent })

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

    local datenode = {
      type = "text",
      val = boxed(datetime()),
      opts = { position = "center", hl = "SdNvimBox" },
    }

    local infonode = {
      type = "text",
      val = boxed(sysinfo()),
      opts = { position = "center", hl = "SdNvimBox" },
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
