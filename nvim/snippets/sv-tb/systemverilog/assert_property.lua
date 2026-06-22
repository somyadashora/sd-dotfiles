-- `assertp` — concurrent assertion with clock + disable iff.
return {
  s("assertp", fmt([[
{name} : assert property (@(posedge {clk}) disable iff (!{rst})
  {expr}
) else $error("{msg}");
]], {
    name = i(1, "a_check"),
    clk = i(2, "clk"),
    rst = i(3, "rst_n"),
    expr = i(4, "/* sequence or property */"),
    msg = i(0, "assertion failed"),
  })),
}
