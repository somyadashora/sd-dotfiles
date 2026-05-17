return {
  "folke/styler.nvim",
  event = "VeryLazy",
  config = function()
    require("styler").setup({
      themes = {
        -- Hardware description languages
        systemverilog = { colorscheme = "monokai-pro-classic" },
        verilog       = { colorscheme = "monokai-pro-classic" },
        vhdl          = { colorscheme = "monokai-pro-classic" },

        -- Scripting / general purpose
        python        = { colorscheme = "catppuccin-frappe" },
        sh            = { colorscheme = "tokyonight-storm" },
        bash          = { colorscheme = "tokyonight-storm" },
        tcl           = { colorscheme = "tokyonight-moon" },

        -- Build / config
        make          = { colorscheme = "tokyonight-moon" },

        -- Git
        gitcommit     = { colorscheme = "catppuccin-latte" },
        gitconfig     = { colorscheme = "catppuccin-latte" },
        gitrebase     = { colorscheme = "catppuccin-latte" },
      },
    })
  end,
}
