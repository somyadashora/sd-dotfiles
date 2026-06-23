vim.g.mapleader = " " -- set leader key to space

local keymap = vim.keymap -- for conciseness

keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode with jk" })

-- Close buffer and switch to previous, or just close if last buffer
keymap.set("n", "<C-q>", function()
  local bufs = vim.fn.getbufinfo({ buflisted = 1 })
  if #bufs > 1 then
    vim.cmd("bp | bd #")
  else
    vim.cmd("bd")
  end
end, { desc = "Close buffer, stay on active buffer" })

-- Disable arrow keys in normal, insert, and visual modes
local arrow_keys = { "<Up>", "<Down>", "<Left>", "<Right>" }
for _, key in ipairs(arrow_keys) do
  keymap.set({ "n", "i", "v" }, key, "<Nop>", { desc = "Disabled arrow key" })
end

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights"})

-- Linter control
keymap.set("n", "<leader>ld", ":lua vim.diagnostic.enable(false)<CR>", { desc = "disable lint messages" })
keymap.set("n", "<leader>le", ":lua vim.diagnostic.enable(true)<CR>", { desc = "enable lint messages" })

-- Cycle line-number modes: hybrid -> absolute -> relative -> two-column -> ...
-- The first three just toggle 'number'/'relativenumber'. The fourth sets the
-- window var `ln_twocol`, which statuscol.nvim reads to render absolute + hybrid
-- side by side (see plugins/statuscol.lua). statuscol keeps the git column on
-- the right in every mode.
keymap.set("n", "<leader>ln", function()
  if vim.w.ln_twocol then                               -- two-column -> hybrid
    vim.w.ln_twocol = false
    vim.wo.number, vim.wo.relativenumber = true, true
    vim.notify("Line numbers: hybrid", vim.log.levels.INFO)
  elseif vim.wo.number and vim.wo.relativenumber then   -- hybrid -> absolute
    vim.wo.number, vim.wo.relativenumber = true, false
    vim.notify("Line numbers: absolute", vim.log.levels.INFO)
  elseif vim.wo.number then                             -- absolute -> relative
    vim.wo.number, vim.wo.relativenumber = false, true
    vim.notify("Line numbers: relative", vim.log.levels.INFO)
  else                                                  -- relative -> two-column
    vim.w.ln_twocol = true
    vim.wo.number, vim.wo.relativenumber = true, false  -- ensure the gutter draws
    vim.notify("Line numbers: two columns (absolute + hybrid)", vim.log.levels.INFO)
  end
  vim.cmd("redraw!") -- statuscolumn doesn't re-eval on a window-var change alone
end, { desc = "Cycle line numbers (hybrid/absolute/relative/two-column)" })

-- Delete mark (dm{char}, mirrors m{char} to set)
keymap.set("n", "dm", function()
  local char = vim.fn.getcharstr()
  vim.cmd("delm " .. char)
end, { desc = "Delete mark" })

-- Spellcheck control
keymap.set("n", "<leader>Sp", ":setlocal spell!<CR>", { desc = "Toggle spellcheck" })
keymap.set("n", "<leader>Sn", "]s", { desc = "Next misspelled word" })
keymap.set("n", "<leader>Sb", "[s", { desc = "Prev misspelled word" })
keymap.set("n", "<leader>Sa", "zg", { desc = "Add word to spellfile" })
keymap.set("n", "<leader>S?", "z=", { desc = "Suggest spelling corrections" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window

keymap.set("n", "<leader>To", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>Tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>Tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>Tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>Tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- quickfix list navigation (enhanced by nvim-bqf)
keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })
keymap.set("n", "]Q", "<cmd>clast<CR>", { desc = "Last quickfix item" })
keymap.set("n", "[Q", "<cmd>cfirst<CR>", { desc = "First quickfix item" })
-- Find an open quickfix OR location-list window in the current tabpage (both
-- have win.quickfix == 1). Location-list windows look identical to quickfix but
-- :cclose/:copen don't act on them — so detect by winid and close by winid,
-- which works for either. (Without this, pressing <leader>qc on a loclist was a
-- no-op, and <leader>qo opened a 2nd quickfix window stacked under the loclist.)
local function find_list_win()
  local cur_tab = vim.fn.tabpagenr()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.tabnr == cur_tab and win.quickfix == 1 then
      return win.winid
    end
  end
  return nil
end
keymap.set("n", "<leader>qo", function()
  local win = find_list_win()
  if win then
    pcall(vim.api.nvim_win_close, win, false) -- close whichever list window is open
  else
    vim.cmd("copen")
  end
end, { desc = "Toggle quickfix list" })
keymap.set("n", "<leader>qc", function()
  local win = find_list_win()
  if win then
    pcall(vim.api.nvim_win_close, win, false)
  end
end, { desc = "Close quickfix/loclist window" })
keymap.set("n", "<leader>qf", function()
  local win = find_list_win()
  if win then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd("copen") -- not open yet → open and focus
  end
end, { desc = "Focus quickfix window" })
keymap.set("n", "<leader>ql", function()
  vim.fn.setqflist({
    {
      bufnr = vim.api.nvim_get_current_buf(),
      lnum = vim.fn.line("."),
      col = vim.fn.col("."),
      text = vim.fn.getline("."),
    },
  }, "a") -- "a" = append to the existing list
end, { desc = "Add current line to quickfix" })
-- Quickfix list STACK: nvim keeps up to 10 lists. Filtering in bqf (zn/zN) or a
-- new :vimgrep pushes a new list and keeps the previous one — walk the stack here.
-- Trouble's quickfix view always mirrors the CURRENT list, but :colder/:cnewer
-- don't fire QuickFixCmdPost, so refresh any open Trouble window after switching.
local function switch_qf_list(cmd)
  vim.cmd("silent! " .. cmd)
  if package.loaded["trouble"] then
    require("trouble").refresh() -- no-op if no Trouble window is open
  end
end
keymap.set("n", "<leader>q[", function() switch_qf_list("colder") end, { desc = "Older quickfix list" })
keymap.set("n", "<leader>q]", function() switch_qf_list("cnewer") end, { desc = "Newer quickfix list" })
keymap.set("n", "<leader>qx", function()
  vim.fn.setqflist({}, "r") -- empty the current list (keeps its slot in the stack)
end, { desc = "Clear quickfix list" })
-- Format every FILE referenced in the quickfix list (once per file), then save.
-- This is the qf-wide counterpart to <leader>vf / <leader>mf (single buffer).
-- Generic per-entry/per-file commands stay manual via :cdo / :cfdo.
keymap.set("n", "<leader>qF", function()
  if vim.tbl_isempty(vim.fn.getqflist()) then
    vim.notify("Quickfix list is empty", vim.log.levels.WARN)
    return
  end
  local cur = vim.api.nvim_get_current_buf()
  local ok, err = pcall(vim.cmd,
    [[cfdo lua require('conform').format({ lsp_fallback = true, timeout_ms = 3000 }) vim.cmd('update')]])
  pcall(vim.api.nvim_set_current_buf, cur) -- return to where we started
  vim.notify(
    ok and "Formatted all files in quickfix list" or ("Format-qf error: " .. tostring(err)),
    ok and vim.log.levels.INFO or vim.log.levels.ERROR
  )
end, { desc = "Format all files in quickfix list" })

