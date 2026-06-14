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

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

-- quickfix list navigation (enhanced by nvim-bqf)
keymap.set("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix item" })
keymap.set("n", "[q", "<cmd>cprev<CR>", { desc = "Prev quickfix item" })
keymap.set("n", "]Q", "<cmd>clast<CR>", { desc = "Last quickfix item" })
keymap.set("n", "[Q", "<cmd>cfirst<CR>", { desc = "First quickfix item" })
keymap.set("n", "<leader>co", function()
  local qf_open = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      qf_open = true
      break
    end
  end
  vim.cmd(qf_open and "cclose" or "copen")
end, { desc = "Toggle quickfix list" })
keymap.set("n", "<leader>cc", "<cmd>cclose<CR>", { desc = "Close quickfix list" })
keymap.set("n", "<leader>cf", function()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 and win.loclist == 0 then
      vim.api.nvim_set_current_win(win.winid)
      return
    end
  end
  vim.cmd("copen") -- not open yet → open and focus
end, { desc = "Focus quickfix window" })

