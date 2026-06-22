-- `uvmclass` — UVM component class with factory registration + constructor.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("uvmclass", fmt([[
class {name} extends {base};

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/
  {body}

/*-------------------------------------------------------------------------------
-- UVM Factory register
-------------------------------------------------------------------------------*/
  // Provide implementations of virtual methods such as get_type_name and create
  `uvm_component_utils({name2})

/*-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------*/
  // Constructor
  function new(string name = "{name3}", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

endclass : {name4}
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
    base = i(2, " /* base class */"),
    body = i(0),
    name2 = rep(1),
    name3 = rep(1),
    name4 = rep(1),
  })),
}
