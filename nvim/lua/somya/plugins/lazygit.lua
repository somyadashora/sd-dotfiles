return {
  "kdheepak/lazygit.nvim",
  cmd = {
    "LazyGit",
    "LazyGitConfig",
    "LazyGitCurrentFile",
    "LazyGitFilter",
    "LazyGitFilterCurrentFile",
  },
  -- optional for floating window border decoration
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  -- Use (nearly) the whole editor for the lazygit float (default 0.9): lazygit
  -- can't change the terminal font, so screen area is the only "see more" knob
  -- on the nvim side. Pairs with the density settings in lazygit/config.yml
  -- (command log hidden, narrower side panel), which is symlinked to
  -- ~/.config/lazygit/config.yml by install.sh.
  init = function()
    vim.g.lazygit_floating_window_scaling_factor = 1
  end,
  -- setting the keybinding for LazyGit with 'keys' is recommended in
  -- order to load the plugin when the command is run for the first time
  keys = {
    { "<leader>lg", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
  },
}
