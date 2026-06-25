return {
  "rmagatti/auto-session",
  -- Lazy: auto_restore is disabled, so the plugin is only needed when one of its
  -- session commands/maps fires. Nothing to do at startup. The old
  -- Session{Save,Restore,Delete} commands are deprecated in favour of the single
  -- `AutoSession` command with subcommands.
  cmd = "AutoSession",
  keys = { "<leader>wr", "<leader>ws" },
  config = function()
    local auto_session = require("auto-session")

    auto_session.setup({
      auto_restore = false,
      suppressed_dirs = { "~/", "~/Dev/", "~/Downloads", "~/Documents", "~/Desktop/" },
    })

    local keymap = vim.keymap

    keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- restore last workspace session for current directory
    keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
  end,
}
