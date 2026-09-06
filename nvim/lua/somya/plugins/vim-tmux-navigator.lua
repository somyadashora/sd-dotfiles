-- Seamless navigation between nvim splits and tmux panes: Alt+hjkl moves to
-- the split in that direction, and when there is no split left it crosses into
-- the neighbouring tmux pane instead of stopping. The tmux half lives in
-- tmux/.tmux.conf, where an `is_vim` check forwards Alt+hjkl into this buffer
-- rather than switching panes.
--
-- ALT rather than Ctrl, deliberately:
--   * <C-j>/<C-k> are neoscroll's half-page scroll (plugins/neoscroll.lua) and
--     stay that way -- that is the muscle memory being protected here.
--   * Ctrl+Shift+hjkl is not representable in legacy terminal encoding (it
--     needs the kitty protocol / CSI-u end to end, which an ETX xterm does not
--     offer), so it would silently degrade to plain Ctrl+j and scroll.
-- Alt is otherwise completely unused in this config and is just an ESC prefix
-- on the wire, so it survives Windows -> ETX -> xterm -> tmux -> nvim.
--
-- `tmux_navigator_no_mappings` is the load-bearing line. Without it the plugin
-- claims <C-h/j/k/l> at startup and neoscroll (lazy on WinScrolled) silently
-- takes <C-j>/<C-k> back on the first scroll -- so the same key navigated for
-- the first few seconds of a session and scrolled afterwards. Declaring the
-- winner here makes it deterministic instead of a load-order race.
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  init = function()
    -- Must be set before the plugin loads, hence init rather than config.
    vim.g.tmux_navigator_no_mappings = 1
  end,
  keys = {
    { "<A-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left split / tmux pane" },
    { "<A-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to below split / tmux pane" },
    { "<A-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to above split / tmux pane" },
    { "<A-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right split / tmux pane" },
  },
}
