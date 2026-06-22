-- `acomb` — combinational always block.
return {
  s("acomb", fmt([[
always_comb begin
  {body}
end
]], {
    body = i(0),
  })),
}
