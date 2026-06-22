-- `package` — package skeleton, name defaults to the file name.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("package", fmt([[
package {name};

endpackage
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
  })),
}
