-- `if` — if block.
return {
  s("if", fmt([[
if ({cond}) begin
  {body}
end
]], {
    cond = i(1, "/* condition */"),
    body = i(0, "/* code */"),
  })),
}
