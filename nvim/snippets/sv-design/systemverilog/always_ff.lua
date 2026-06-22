-- `aff` — always_ff with asynchronous active-low reset.
return {
  s("aff", fmt([[
always_ff @(posedge {clk} or negedge {rst}) begin
  if (!{rst2}) begin
    {rstbody}
  end else begin
    {body}
  end
end
]], {
    clk = i(1, "clk"),
    rst = i(2, "rst_n"),
    rst2 = rep(2),
    rstbody = i(3),
    body = i(0),
  })),
}
