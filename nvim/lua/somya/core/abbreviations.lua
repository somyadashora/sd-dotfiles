-- Insert-mode abbreviations (`:iabbrev`): type the trigger, then any
-- non-keyword char (space, punctuation, <CR>) and Vim swaps in the expansion.
--
-- Two hazards shape what is safe to put here:
--   1. An abbreviation fires on a *whole word*, so a trigger that is also a
--      word you type on purpose (`if`, `end`, ...) would expand against your
--      will. We sidestep that two ways: the prose triggers are *misspellings*
--      (you never type them deliberately), and every convenience expansion
--      carries an `x` prefix (`xdate`, `xtodo`) -- a shape that almost never
--      appears as a real word or identifier.
--   2. SystemVerilog keyword fixes are kept *buffer-local* to `.sv`/`.svh`
--      (set on FileType) so they can't bite while you're writing prose notes.
--
-- Structural SV constructs (module/class/always_ff/...) live in the LuaSnip
-- snippet sets, not here -- abbreviations only cover inline keywords + typos.

local function iabbrev(lhs, rhs)
  -- Build the raw command: everything after `lhs` is taken as the rhs, so
  -- expansions may contain spaces (e.g. the signature) without extra quoting.
  vim.cmd("iabbrev " .. lhs .. " " .. rhs)
end

-- 1. Prose typo fixes -- global, safe everywhere (incl. notes). ---------------
local prose = {
  { "teh",         "the" },
  { "adn",         "and" },
  { "nad",         "and" },
  { "tehn",        "then" },
  { "taht",        "that" },
  { "waht",        "what" },
  { "wiht",        "with" },
  { "becuase",     "because" },
  { "recieve",     "receive" },
  { "seperate",    "separate" },
  { "definately",  "definitely" },
  { "occured",     "occurred" },
  { "occurance",   "occurrence" },
  { "thier",       "their" },
  { "alot",        "a lot" },
  { "accross",     "across" },
  { "arguement",   "argument" },
  { "begining",    "beginning" },
  { "enviroment",  "environment" },
  { "neccessary",  "necessary" },
  { "successfull", "successful" },
  { "untill",      "until" },
  { "lenght",      "length" },
  { "widht",       "width" },
}
for _, a in ipairs(prose) do
  iabbrev(a[1], a[2])
end

-- 2. `x`-prefixed conveniences -- global, distinctive triggers for notes. -----
-- Date/time use <expr> abbreviations so they expand to the *current* moment.
vim.cmd([[iabbrev <expr> xdate strftime("%Y-%m-%d")]])
vim.cmd([[iabbrev <expr> xtime strftime("%H:%M")]])
vim.cmd([[iabbrev <expr> xnow  strftime("%Y-%m-%d %H:%M")]])

iabbrev("xtodo", "TODO:")
iabbrev("xfix", "FIXME:")
iabbrev("xnote", "NOTE:")
iabbrev("xsig", "Somya Dashora")
iabbrev("xmail", "somyadashora@gmail.com")

-- 3. SystemVerilog keyword typo fixes -- buffer-local to .sv/.svh. ------------
local sv = {
  { "lgoic",      "logic" },
  { "logc",       "logic" },
  { "alwyas",     "always" },
  { "alwasy",     "always" },
  { "bgein",      "begin" },
  { "begni",      "begin" },
  { "edn",        "end" },
  { "fucntion",   "function" },
  { "funtion",    "function" },
  { "paramter",   "parameter" },
  { "paramater",  "parameter" },
  { "localparm",  "localparam" },
  { "lcoalparam", "localparam" },
  { "inteface",   "interface" },
  { "interafce",  "interface" },
  { "modlue",     "module" },
  { "moduel",     "module" },
  { "endmoduel",  "endmodule" },
  { "assgin",     "assign" },
  { "asign",      "assign" },
  { "genrate",    "generate" },
  { "pacakge",    "package" },
  { "typdef",     "typedef" },
  { "defualt",    "default" },
  { "retrun",     "return" },
  { "unqiue",     "unique" },
  { "prioirty",   "priority" },
}
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("SVAbbrev", { clear = true }),
  pattern = "systemverilog",
  desc = "SystemVerilog keyword typo-fix abbreviations (buffer-local)",
  callback = function()
    for _, a in ipairs(sv) do
      vim.cmd("iabbrev <buffer> " .. a[1] .. " " .. a[2])
    end
  end,
})
