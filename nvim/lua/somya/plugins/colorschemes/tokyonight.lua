return {
  {
    "folke/tokyonight.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
    -- The default scheme (core/theme.lua → M.default = "monokai-pro") is applied
    -- by the `colorscheme` command below, so its plugin must already be loaded.
    -- Listing it as a dependency makes lazy load + setup() it before this config
    -- runs. (Swap this if you change M.default to another lazy scheme.)
    dependencies = { "loctvl842/monokai-pro.nvim" },
    config = function()
      local bg = "#011628"
      local bg_dark = "#011423"
      local bg_highlight = "#143652"
      local bg_search = "#e8d4a8" -- pastel parchment (was #0A64AC dark blue)
      local bg_visual = "#275378"
      local fg = "#CBE0F0"
      local fg_dark = "#B4D0E9"
      local fg_gutter = "#5a8fa8"
      local border = "#547998"

      require("tokyonight").setup({
        style = "night",
        on_colors = function(colors)
          colors.bg = bg
          colors.bg_dark = bg_dark
          colors.bg_float = bg_dark
          colors.bg_highlight = bg_highlight
          colors.bg_popup = bg_dark
          colors.bg_search = bg_search
          colors.bg_sidebar = bg_dark
          colors.bg_statusline = bg_dark
          colors.bg_visual = bg_visual
          colors.border = border
          colors.fg = fg
          colors.fg_dark = fg_dark
          colors.fg_float = fg
          colors.fg_gutter = fg_gutter
          colors.fg_sidebar = fg_dark
        end,
      })
      -- load the colorscheme here (default lives in core/theme.lua — edit it
      -- there to change the startup scheme; browse alternatives via <leader>uc)
      vim.cmd("colorscheme " .. require("somya.core.theme").default)

      -- Monokai Pro 'pro' accent palette (single source for the overrides below):
      --   yellow #ffd866  red #ff6188  orange #fc9867  green #a9dc76
      --   cyan   #78dce8  purple #ab9df2  bg #2d2a2e
      local mono_yellow     = "#ffd866"  -- accent3
      local mono_yellow_dim = "#9a8c52"  -- desaturated accent3 for inactive lines
      local mono_bg         = "#2d2a2e"
      local mono_cursorline = "#403e41"  -- dimmed5: subtle warm band over mono_bg

      local function apply_hl_overrides(ns)
        ns = ns or 0
        -- Warm monokai band (was tokyonight navy #143652, which clashed on the
        -- #2d2a2e monokai background).
        vim.api.nvim_set_hl(ns, "CursorLine",    { bg = mono_cursorline })
        -- Block cursor + line numbers in monokai yellow (was pink/blue).
        vim.api.nvim_set_hl(ns, "Cursor",        { fg = mono_bg, bg = mono_yellow })
        vim.api.nvim_set_hl(ns, "lCursor",       { fg = mono_bg, bg = mono_yellow })
        vim.api.nvim_set_hl(ns, "LineNr",        { fg = mono_yellow_dim })
        vim.api.nvim_set_hl(ns, "CursorLineNr",  { fg = mono_yellow, bold = true })
        vim.api.nvim_set_hl(ns, "MarkSignHL",    { fg = "#ff475f", bold = true })
        vim.api.nvim_set_hl(ns, "MarkSignNumHL", { fg = "#ff475f", bold = true })
        vim.api.nvim_set_hl(ns, "Search",    { bg = "#e8d4a8", fg = "#1e1e2e" })
        vim.api.nvim_set_hl(ns, "IncSearch", { bg = "#f0a07a", fg = "#1e1e2e", bold = true })
        vim.api.nvim_set_hl(ns, "CurSearch", { bg = "#f0a07a", fg = "#1e1e2e", bold = true })
      end

      -- global colorscheme changes (tokyonight, etc.)
      apply_hl_overrides(0)
      vim.api.nvim_create_autocmd("ColorScheme", { callback = function() apply_hl_overrides(0) end })

      -- styler.nvim loads per-filetype colorschemes into a window-local namespace
      -- without firing ColorScheme. Apply overrides into every styler namespace
      -- after it has been created (nvim_get_namespaces works on all nvim versions).
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        callback = function()
          vim.schedule(function()
            for name, ns in pairs(vim.api.nvim_get_namespaces()) do
              if name:match("^styler_") then
                apply_hl_overrides(ns)
              end
            end
          end)
        end,
      })
    end,
  },
}
