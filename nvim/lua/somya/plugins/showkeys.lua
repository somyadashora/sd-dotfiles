return {
  "nvzone/showkeys",
  cmd = "ShowkeysToggle",
  keys = {
    { "<leader>sk", "<cmd>ShowkeysToggle<cr>", desc = "Toggle key display" },
  },
  opts = {
    timeout = 3,
    maxkeys = 5,
    position = "top-right",
    show_count = false,
    excluded_modes = {},
    winopts = {
      border = "rounded",
    },
  },
}
