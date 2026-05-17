vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

opt.relativenumber = true
opt.number = true

-- tabs & indentation
opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false
opt.sidescrolloff = 36
-- spell check
opt.spelllang = 'en_us'
opt.spell = false
-- :spellr
-- if there’s a word you frequently misspell, using :spellr
-- is a quick and easy one stop shop for fixing all the misspellings of that type.


-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want case-sensitive

-- cursor line
opt.cursorline = true
opt.cursorlineopt ='both' -- highlight both the number and the line of the cursor

-- appearance


-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes:2" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- tkinter daemon owns X CLIPBOARD so ETX bridges it to Windows (no xclip/xsel needed)
local clip = vim.fn.stdpath('config') .. '/scripts/nvim-clip'
vim.g.clipboard = {
  name  = 'nvim-clip',
  copy  = { ['+'] = { clip, 'copy' }, ['*'] = { clip, 'copy' } },
  paste = { ['+'] = { clip, 'paste' }, ['*'] = { clip, 'paste' } },
}
opt.clipboard:append("unnamedplus") -- use system clipboard as default register

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom
