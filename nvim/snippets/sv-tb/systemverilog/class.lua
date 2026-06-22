-- `class` — class skeleton with mirrored end label, name defaults to file name.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("class", fmt([[
class {name} extends {base};

endclass : {name2}
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
    base = i(2, " /* base class */"),
    name2 = rep(1),
  })),
}
