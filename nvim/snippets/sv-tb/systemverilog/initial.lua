-- `initial` — initial block (testbench).
return {
  s("initial", fmt([[
initial begin
  {body}
end
]], {
    body = i(0),
  })),
}
