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
      vim.api.nvim_set_hl(0, "CursorLine",   { bg = "#143652" })
      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#ff79c6", bold = true })
      vim.api.nvim_set_hl(0, "MarkSignHL",   { fg = "#ff475f", bold = true })
      vim.api.nvim_set_hl(0, "MarkSignNumHL", { fg = "#ff475f", bold = true })
      -- search: yellow for all matches, peach for the active/current one
      vim.api.nvim_set_hl(0, "Search",    { bg = "#e8d4a8", fg = "#1e1e2e" })
      vim.api.nvim_set_hl(0, "IncSearch", { bg = "#f0a07a", fg = "#1e1e2e", bold = true })
      vim.api.nvim_set_hl(0, "CurSearch", { bg = "#f0a07a", fg = "#1e1e2e", bold = true })
    end,
  },
}
