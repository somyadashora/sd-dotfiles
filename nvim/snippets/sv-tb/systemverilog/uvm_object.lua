-- `uvmobj` — UVM object class with object_utils + constructor.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("uvmobj", fmt([[
class {name} extends {base};

  `uvm_object_utils({name2})

  function new(string name = "{name3}");
    super.new(name);
  endfunction : new

  {body}

endclass : {name4}
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
    base = i(2, "uvm_object"),
    body = i(0),
    name2 = rep(1),
    name3 = rep(1),
    name4 = rep(1),
  })),
}
