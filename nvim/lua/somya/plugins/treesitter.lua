return {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
      "windwp/nvim-ts-autotag",
    },
    config = function()
      local parsers = {
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
        "python",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
        "tcl",
        "make",
        "vhdl",
        "systemverilog",
      }

      local treesitter = require("nvim-treesitter")

      treesitter.setup({
        install_dir = vim.fn.stdpath("data") .. "/site",
      })

      -- nvim-treesitter's main branch needs the tree-sitter CLI to compile
      -- parsers. On hosts without it (e.g. old glibc, no cargo/rustup) parsers
      -- can't be built, so disable treesitter dynamically and let Neovim's
      -- built-in syntax highlighting take over instead.
      local has_cli = vim.fn.executable("tree-sitter") == 1

      if has_cli then
        treesitter.install(parsers)
      else
        vim.notify(
          "tree-sitter CLI not found; treesitter disabled, using built-in syntax",
          vim.log.levels.WARN
        )
        pcall(vim.cmd, "syntax enable")
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          local buf = args.buf
          -- Use treesitter only when the CLI is present and a parser actually
          -- starts; otherwise fall back to built-in syntax for this buffer.
          if has_cli and pcall(vim.treesitter.start, buf) then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          elseif vim.bo[buf].syntax == "" then
            vim.bo[buf].syntax = vim.bo[buf].filetype
          end
        end,
      })

      require("nvim-ts-autotag").setup()
    end,
  }
