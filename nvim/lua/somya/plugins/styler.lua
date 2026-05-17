return {
  "folke/styler.nvim",
  event = "VeryLazy",
  config = function()
    require("styler").setup({
      themes = {
        -- Hardware description languages
        systemverilog = { colorscheme = "catppuccin-mocha" },
        verilog       = { colorscheme = "catppuccin-mocha" },
        vhdl          = { colorscheme = "catppuccin-macchiato" },

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
