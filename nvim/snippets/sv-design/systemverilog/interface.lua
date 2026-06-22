-- `interface` — interface skeleton, name defaults to the file name.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("interface", fmt([[
interface {name} ();

endinterface
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
  })),
}
