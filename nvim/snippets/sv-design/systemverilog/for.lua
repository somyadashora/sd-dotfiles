-- `for` — for loop; loop variable mirrors across condition + increment.
return {
  s("for", fmt([[
for (int {ivar} = 0; {ivar2} < {count}; {ivar3}++) begin
  {body}
end
]], {
    count = i(1, "count"),
    ivar = i(2, "i"),
    ivar2 = rep(2),
    ivar3 = rep(2),
    body = i(0, "/* code */"),
  })),
}
