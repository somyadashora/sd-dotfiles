-- `uvmseq` — UVM sequence class with body() task.
local function fname()
  return vim.fn.expand("%:t:r")
end

return {
  s("uvmseq", fmt([[
class {name} extends uvm_sequence #({item});

  `uvm_object_utils({name2})

  function new(string name = "{name3}");
    super.new(name);
  endfunction : new

  virtual task body();
    {body}
  endtask : body

endclass : {name4}
]], {
    name = d(1, function() return sn(nil, i(1, fname())) end),
    item = i(2, "my_seq_item"),
    body = i(0),
    name2 = rep(1),
    name3 = rep(1),
    name4 = rep(1),
  })),
}
