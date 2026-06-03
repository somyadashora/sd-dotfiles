return {
  {
    "folke/tokyonight.nvim",
    priority = 1000, -- make sure to load this before all the other start plugins
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
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])

      local function apply_hl_overrides(ns)
        ns = ns or 0
        vim.api.nvim_set_hl(ns, "CursorLine",    { bg = "#143652" })
        vim.api.nvim_set_hl(ns, "LineNr",        { fg = "#5a8fa8" })
        vim.api.nvim_set_hl(ns, "CursorLineNr",  { fg = "#ff79c6", bold = true })
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
