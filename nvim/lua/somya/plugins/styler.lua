return {
  "folke/styler.nvim",
  event = "VeryLazy",
  -- Pull in the colorschemes styler switches to, so they load with styler rather
  -- than eagerly at startup. (catppuccin/tokyonight already load via priority.)
  dependencies = { "loctvl842/monokai-pro.nvim" },
  config = function()
    require("styler").setup({
      themes = {
        -- Hardware description languages
        systemverilog = { colorscheme = "monokai-pro-spectrum" },
        verilog       = { colorscheme = "monokai-pro-spectrum" },
        vhdl          = { colorscheme = "monokai-pro-spectrum" },

        -- Scripting / general purpose
        python        = { colorscheme = "catppuccin-frappe" },
        sh            = { colorscheme = "tokyonight-storm" },
        bash          = { colorscheme = "tokyonight-storm" },
        tcl           = { colorscheme = "tokyonight-moon" },

        -- Build / config
        make          = { colorscheme = "tokyonight-moon" },

        -- Markdown
        markdown      = { colorscheme = "catppuccin-mocha" },

        -- Git
        gitcommit     = { colorscheme = "catppuccin-latte" },
        gitconfig     = { colorscheme = "catppuccin-latte" },
        gitrebase     = { colorscheme = "catppuccin-latte" },
      },
    })
  end,
}
