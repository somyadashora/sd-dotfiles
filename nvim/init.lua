-- Enable the experimental Lua module loader (bytecode cache) before anything
-- else requires modules — speeds up every subsequent require() at startup.
vim.loader.enable()

require("somya.core")
require("somya.lazy")
