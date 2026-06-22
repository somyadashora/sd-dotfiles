-- `genfor` — generate for loop with named block.
return {
  s("genfor", fmt([[
generate
  for (genvar {gv} = 0; {gv2} < {count}; {gv3}++) begin : {label}
    {body}
  end
endgenerate
]], {
    gv = i(1, "i"),
    gv2 = rep(1),
    count = i(2, "N"),
    gv3 = rep(1),
    label = i(3, "g_loop"),
    body = i(0),
  })),
}
