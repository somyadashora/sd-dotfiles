-- `module` — module skeleton, name defaults to the file name.
-- (snip_env globals s, i, d, sn, fmt are injected by LuaSnip's lua loader.)
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("module", fmt([[
module {name} (
  input clk,    // Clock
  input clk_en, // Clock enable
  input rst_n,  // Asynchronous reset, active low
  {body}
);

endmodule
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
    body = i(0),
  })),
}
