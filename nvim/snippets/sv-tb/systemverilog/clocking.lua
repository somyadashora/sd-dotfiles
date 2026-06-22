-- `clocking` — clocking block (interface / testbench).
return {
  s("clocking", fmt([[
clocking {name} @(posedge {clk});
  default input #1step output #1;
  {body}
endclocking
]], {
    name = i(1, "cb"),
    clk = i(2, "clk"),
    body = i(0),
  })),
}
