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
      -- Bootstrap the theme: load the startup colorscheme (core/theme.lua →
      -- M.default) and wire per-colorscheme highlight overrides. Both — and the
      -- override colors themselves — live in core/theme.lua now, so this file is
      -- just the eager priority-1000 trigger, no longer the "theme main file".
      -- tokyonight + monokai-pro (its dependency) are both set up by this point.
      require("somya.core.theme").bootstrap()
    end,
  },
}
