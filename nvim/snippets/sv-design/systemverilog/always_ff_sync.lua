-- `affs` — always_ff with synchronous active-low reset.
return {
  s("affs", fmt([[
always_ff @(posedge {clk}) begin
  if (!{rst}) begin
    {rstbody}
  end else begin
    {body}
  end
end
]], {
    clk = i(1, "clk"),
    rst = i(2, "rst_n"),
    rstbody = i(3),
    body = i(0),
  })),
}
